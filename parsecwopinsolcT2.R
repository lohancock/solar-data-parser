substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

# Note re the above: substrRight was contributed by Andrie and 
# I found it on stack overflow.



parsecwopinsolc <- function(filedate) {

  # note that the c in the name of the routine refers to the correction flagged below,
  # which straightens out the use of zenith angle rahter than altitude.
  # My approximation of R uses altitude; Corripio's insol computes zenith angle.

  # Read data and prepare name of output file  
  
  filename<-paste("~/jtech/data/L",filedate,".txt.gz",sep="")
  mydata<-readLines(filename)
  
  # Read in the list of lats, lons, and looked-up elevation.
  
  llename<-paste("~/jtech/data/latlonelevation.txt",sep="")
  lle<-read.table(llename,sep="\t",colClasses="numeric",skip=1)
  latlonelev<-data.frame(lat=lle[,1],lon=lle[,2],elev=lle[,3])
    
  # Remove from data all duplicates, convert to UTF-8, remove stray characters, remove duplicates again.

  report<-unique(mydata)
  report<-iconv(report,to="UTF-8",sub="qzt")
  report <- gsub("[^[:print:]]","qzt",report)
  report<-gsub("\t","qzt",report)
  
  
# Next comes another error fix:  this is why bad lines were getting through.
  report<-unique(report)
    
  # Prepare the date of the archive and the date of the day before, as strings and as dates.
  
  thisyear<-substr(filedate,1,4)
  thismonth<-substr(filedate,5,6)
  thisday<-substr(filedate,7,8)
  thisdate<-paste(thisyear,thismonth,thisday,sep="-")

  thisdateasdate<-as.Date(thisdate)  
  yesterdayasdate<-thisdateasdate-1

  yesterdayyear<-substr(as.character(yesterdayasdate),1,4)
  yesterdaymonth<-substr(as.character(yesterdayasdate),6,7)
  yesterdayday<-substr(as.character(yesterdayasdate),9,10)
  yesterdaydate<-paste(yesterdayyear,yesterdaymonth,yesterdayday,sep="-")
    
  # Extract station name and timestamp sent with record.  Convert to upper.  
  # Remark:  It wouldn't work to simply convert the original report 
  # because the data parsing requires the upper vs lower distinction
  # especially L versus l, be maintained.
  
  stationpat<-"([a-zA-Z0-9-]{1,})(>)"
  statns<- str_match(report,stationpat)
  stationname<- toupper(statns[,2])
  
  timepat<-"(>)([0-9]{6})(z)"
  dtimes<- str_match(report,timepat)
  datatimes<-dtimes [,3]
  
  # Extract day of the month from packet, compare it to archive day of month
  # and flag as same day, day before, or other.

  recordday<-substr(datatimes,1,2)

  dateflag<-integer()
  dateflag[recordday==thisday]<-1
  dateflag[recordday==yesterdayday]<-2
  dateflag[!(recordday==thisday|recordday==yesterdayday)]<-3
  
  # Use archive day together with packet-reported time (hours-min) to assemble a timestamp.  
  # But if dateflag is 2, subtract a day.
  # And if dateflag is 3, set timestamp to NA.

  recordhour<-substr(datatimes,3,4)
  recordmin<-substr(datatimes,5,6)
  recordtime<-paste(recordhour,recordmin,sep=":")  
  recordstamp<-paste(thisdate,recordtime,sep=" ")

  # Convert to obtain a date in class POSIX where we use 
  # day before if dateflag is 2, NA if it is 3.
  
  z <- strptime(recordstamp, "%Y-%m-%d %H:%M",tz='GMT')
  z<-z-(ifelse(dateflag==2,86400,0))
  z[which(dateflag==3)]<-NA
  
  latpat<-"([z]{1})([0-9]{4}.[0-9]{2})([N n S s]{1})"
  latparts<-str_match(report,latpat)
  lat<-latparts[,3]
  latd<-as.numeric(substr(lat,1,2))
  latmin<-as.numeric(substr(lat,3,7))
  latitude<-(latd+(latmin/60))

  latsign<-toupper(latparts[,4])
  latitude<-ifelse(latsign=="S",latitude*-1,latitude) 

# Remove unphysical latitudes.  Indeed some such are reported.  
# See these stations listing latitudes less than 70S:  DW3728, EW4947, EW5294
# it is probably a format issue but I haven't looked.
  
  latitude<-ifelse(latitude<(-90.),NA,latitude)
  latitude<-ifelse(latitude>(90.),NA,latitude)
  
  lonpat<-"(/)([0-9]{5}.[0-9]{2})([E e W w])"
  lonparts<-str_match(report,lonpat)
  lon<-lonparts[,3]
  lond<-as.numeric(substr(lon,1,3))
  lonmin<-as.numeric(substr(lon,4,8))
  longitude<-(lond+(lonmin/60))

  lonsign<-toupper(lonparts[,4])
  longitude<-ifelse(lonsign=="W",longitude*-1,longitude)  
  
  windpat<-"(_)([0-9]{3})/([0-9]{3})"
  windparts<-str_match(report,windpat)
  winddir<-as.numeric(windparts[,3])
  windknots<-as.numeric(windparts[,4])
  
  gustpat<-"(g)([0-9]{3})([a-z]){1}"
  gparts<-str_match(report,gustpat)
  gust<-as.numeric(gparts[,3])

# Note I have my doubts about some of these gust values which don't seem 
# to fall anywhere above 100 except  bang at 255.

  tpat<-"(t)(-*)([0-9]{2,3})([a-z A-Z]){1}"
  tparts<-str_match(report,tpat)
  temp<-as.numeric(tparts[,4])
  temp<-ifelse(tparts[,3]=="-",temp*-1,temp)  

# Added the following to set out of bounds values of temp to NA, because
# when insol encounters them it halts execution.

#  badT<-which(-50>temp | temp>100)
#  is.na(temp[badT])<-TRUE

# REVISION november 2015:  temp greater than 100 set to NA is too strict.  Note that as 
# of today all in the database use the old version.  May have emptied out values in the tropics.
#
  
  badT<-which(-100>temp | temp>150)
  is.na(temp[badT])<-TRUE
  
    
  temp3types<-convert_T(temp,"F")
  tempK<-temp3types[,1]

# HERE is where to put the correction such that unphysical values of tempK are set to NULL or something
# so insol doesn't try to use them.  So far as I know (a/o June 1, 2015), the problem occurs only
# on 20130128 and a few days just after that.

  
  rpat<-"(r)([0-9]{3})([a-z A-Z]){1}"
  rparts<-str_match(report,rpat)
  rainfallhour<-as.numeric(rparts[,3])
  
  ppat<-"(p)([0-9]{3})([a-z A-Z]){1}"
  pparts<-str_match(report,ppat)
  rainfall24h<-as.numeric(pparts[,3])
  
  bigppat<-"(P)([0-9]{3})([a-z A-Z]){1}"
  bigpparts<-str_match(report,bigppat)
  rainfalltoday<-as.numeric(bigpparts[,3])
  
  hpat<-"(h)([0-9]{2})"
  hparts<-str_match(report,hpat)
  relativehumidity<-as.numeric(hparts[,3])
  
# Note there are cases of a station using a leading blank in baropressure for low values.
# I have used a space in the regex but if that is ambiguous and causes problems here is where
# to find tighter alternatives: http://stackoverflow.com/questions/559363/matching-a-space-in-regex

  bpat<-"(b)([0-9 ]{5})"
  bparts<-str_match(report,bpat)
  baropressure<-as.numeric(bparts[,3])

# Search for L or L, and 3 or 4 numbers and turn the result into a number.

  lpat<-"([L l])([0-9]{3,4})"
  lparts<-str_match(report,lpat)
  lrec<-lparts[,1]

# Flag data that uses 4 chars instead of expected protocol 3.

  lcharerr<-nchar(lparts[,1])>4

# Flag data as to whether it is L or l.

  smallell<-(lparts[,2]=="l")

# Turn it into a number

  lnum<-as.integer(lparts[,3])

# To finalize it:  If it is using wrong protocol, use the raw value.  
# Yes, the irony is that wrong protocol provides right data easily.
# I guess that is why people use it.  
# Now, if it is correct protocol and uses a small l, prepare an addend of 1000. 
  laddend<-ifelse(lcharerr==0,smallell*1000,0)
  lfin<-lnum+laddend
  
  techbreak<-str_locate(report,lpat)
  totalchar<-nchar(report)
  tsuffix<-totalchar-techbreak[,2]
  tech<-substrRight(report,tsuffix)

  options(digits=12)

# Now work with insol to obtain a modeled comparator value for L.
  
  cwopJD<-JD(z)
  cwopDay<-daylength(latitude,longitude,cwopJD,0)


# Next, to get noon altitude of sun, compute
# time of local solar transit, and compute zenith angle of sun that corresponds.

  cwopSunrise<-cwopDay[,1]
  cwopDaylength<-cwopDay[,3]
  cwopTransit<-cwopSunrise +(0.5*cwopDaylength)

  cwopDec<-declination(cwopJD)

# cwopEqtime is in minutes.  Note that cwopEqtime is about -10 on January 17.  

  cwopEqtime<-eqtime(cwopJD)

# cwopSunv requires a time in JD, lat, lon, tz.

  cwopSunv<-sunvector(cwopJD,latitude,longitude,0)
  cwopSunpos<-sunpos(cwopSunv)

# As to the next - a few stations have measurements with zenith angles of more than 90 which would mean the Sun
# was below the horizon.  I looked and the clock seems OK.  What it is, is they
# seem to have been recording moon or aurora or office lights or something,
# long before sunrise and after sunst.  Or maybe just an error. 
# I will check these stations on other days.

  cwopZenith<-cwopSunpos[,2]

  cwopTransitJD<- floor(cwopJD) - 0.5 + (cwopTransit/24.)

  cwopTransitSunv<-sunvector(cwopTransitJD,latitude,longitude,0)
  cwopTransitSunpos<-sunpos(cwopTransitSunv)
  cwopTransitZenith<-cwopTransitSunpos[,2]

# NOTE - Below is the edit which makes this parsecwopinsolc rather than parsecwopinsol.
# The need concerns fact hat the zenith angle at transit (Corripio) is zero when sun is at zenith, 
# while my formula uses solar altitude, which is zero when sun is at the horizon.  
# So I have added a line to compute altitude, and rewritten R to use that, not zenith angle.

  cwopTransitSolarAltitude=90-cwopTransitZenith;

# And at last, I would use the value for zenith angle of sun at transit, to compute R.

  maxRadius<-(-1)*6.378/sin(radians(cwopDec)) 
  cwopR<-maxRadius*cos(radians(cwopTransitSolarAltitude)) 

# The above produces values of R less than the radius of the Earth.
# These however correspond to latitudes in summer.
# I thought of deleting these but decided against.


# For elevation make a vector of looked-up values
# note this produces some negative values - haven't checked why but maybe
# it is because some stations are reporting positions in midocean and the DEM is reporting
# bathymetry.  In these cases I will check but probably the coords are wrong.
# Let us recall the stations sited at zero zero, which is Gulf of Guinea, which has a DART
# station but I don't think that is sending L to CWOP.

   
  rlatitude<-round(latitude,3)
  rlongitude<-round(longitude,3)
  rlatlonelev<-round(latlonelev,3)
  
  ndata<-length(report)

# the first one, findelevationi, is not used in the end, but it is handy
# for error checking so I am keeping it for that in case useful.

  findelevationi<-function(i) {
    hmatch<-which(rlatlonelev$lat==rlatitude[i] & rlatlonelev$lon==rlongitude[i])
    hmatch
  }

  findelevationh<-function(i) {
    hmatch<-which(rlatlonelev$lat==rlatitude[i] & rlatlonelev$lon==rlongitude[i])
    mean(latlonelev[hmatch,3])
  }

  hite<-vector()
  for (i in seq(1:ndata)){hite[i]<-(findelevationh(i))}


  # Now that i have hite to use as elevation vecot,
  # all is prepared for computation of insol, using lookup values for height,
  # and typical values for O3 and alphag because I usually do not know these.

  cwopInsol90<-insolation(cwopZenith,cwopJD,hite,90,relativehumidity,tempK,.02,0.5)
  cos_inc_sfc=cwopSunv%*%as.vector(normalvector(0,0))
  cos_inc_sfc[cos_inc_sfc<0]=0
  cwopInsolSum90<-cwopInsol90[,1]*cos_inc_sfc +cwopInsol90[,2]
  cwopDiffuse90<-cwopInsol90[,2]
  cwopTau90<--1*log(lfin/cwopInsolSum90)

# zenith Zenith angle in degrees.
# jd Julian Day.
# height Altitude above sea level.
# visibility Visibility [km].
# RH Relative humidity [%].
# tempK Air temperature [K].


  outtable<-data.frame(report,stationname,thisdate, datatimes,dateflag,z,latitude,latsign,longitude,
                       lonsign,winddir,windknots,gust,temp,
                       rainfallhour,rainfall24h,rainfalltoday,relativehumidity,baropressure,
                       lrec,lfin,lcharerr,tech,cwopJD,cwopSunpos[,1],cwopZenith,
                       cwopInsolSum90,
                       cwopTau90,cwopDiffuse90,
                       cwopDaylength,cwopDec,cwopEqtime,cwopR,hite)
  
  mydataout <- paste("~/jtech/data/LPIC2",filedate,".txt",sep="")
  write.table(outtable,mydataout,sep="\t",row.names=FALSE,quote=FALSE,col.names=FALSE) 

 
# Systematic errors to mention:  Insol expects the Eppley to lie flat; it may not.
# We expect no actual shading.  Pah.
# I think we shall use usually visibility 100 km; thus we will produce
# a tau that includes atmospheric effects as well as anything other.
# Seasonal effects, wrong lats, wrong longitudes, clock problems, miscalibration,
# meaning of the archive value versus the timing of the avering from which L is drawn.
# 

}  
