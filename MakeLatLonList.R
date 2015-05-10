MakeLList <- function(filedate) {

  # Read data
  
  filename<-paste("d:/a solar data/2014 solar data/L",filedate,".txt.gz",sep="")
  mydata<-readLines(filename)
  
  # Read in the existing list of lats and lons.  Call the result "oldlatlon"
  
  listname<-paste("d:/solardataparser/latlonlist.txt",sep="")
  myllist<-read.table(listname,sep=",",colClasses="numeric",skip=1)
  oldlatlon<-data.frame(latitude=myllist[,1],longitude=myllist[,2])
  
  # Revert to data.  Tidy it:  remove duplicates, convert to UTF-8, remove stray characters, remove duplicates again.
  # All the next is just taken from the parse routine, not trimmed. 
  # Much isn't necessary.

  report<-unique(mydata)
  report<-iconv(report,to="UTF-8",sub="qzt")
  report <- gsub("[^[:print:]]","qzt",report)
  report<-unique(mydata)
    
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
      
  stationpat<-"([a-zA-Z0-9-]{1,})(>)"
  statns<- str_match(report,stationpat)
  stationname<- toupper(statns[,2])
  
  timepat<-"(>)([0-9]{6})(z)"
  dtimes<- str_match(report,timepat)
  datatimes<-dtimes [,3]
  
  recordday<-substr(datatimes,1,2)

  dateflag<-integer()
  dateflag[recordday==thisday]<-1
  dateflag[recordday==yesterdayday]<-2
  dateflag[!(recordday==thisday|recordday==yesterdayday)]<-3
  
  recordhour<-substr(datatimes,3,4)
  recordmin<-substr(datatimes,5,6)
  recordtime<-paste(recordhour,recordmin,sep=":")  
  recordstamp<-paste(thisdate,recordtime,sep=" ")

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
# it is probably a format issue but since I don't know...
  
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
  
# Here is the data from this file

  lltable<-data.frame(report,stationname,thisdate, latitude,longitude)

# Here are the uniqe values of lat and lon from this file.

  newlatlon<-unique(lltable[c("latitude","longitude")])

# We append these new values to the existing latlon file

  longlatlon<-rbind(oldlatlon,newlatlon)

# Then we take only the unique values from the combination

  latlon<-unique(longlatlon[c("latitude","longitude")])  

# We prepare a name for the output

  llout <- paste("d:/0parseinsolcwop/latlonlist.txt",sep="")

# We write to the output file we have named.

  write.table(latlon,llout,sep=",",row.names=FALSE,quote=FALSE,col.names=TRUE) 

# And in a follow-on step I can use this url:  http://www.gpsvisualizer.com/convert?output_elevation

# Systematic errors to mention:  Insol expects the Eppley to lie flat; it may not.
# We expect no actual shading.  Pah.
# I think we shall use usually visibility 100 km; thus we will produce
# a tau that includes atmospheric effects as well as anything other.
# Seasonal effects, wrong lats, wrong longitudes, clock problems, miscalibration,
# meaning of the archive value versus the timing of the avering from which L is drawn.
# 

}  
  
