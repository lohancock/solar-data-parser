# solar-data-parser
Herewith a set of tools to make the archive of solar radiation data from the voluntary observers program (CWOP) available to all.

The NOAA-CWOP Solar Data archive, launched in February 2009, has accumulated a quarter billion observations of solar radiation from a global network of contributing weather stations.  As to organization, the archive is comprised of daily archives, each a collection of reports gathered within a 24-hour period beginning at 11 PM UTC, named 20090218.tar.gz and so on.  By February 2015, the number of contributing stations had risen from about 800 (at archive initiation) to about 2500.  The network has always been global, although concentrated in the US, Europe and Australia.  Most stations send accompanying met data.  Links to the archive can be found at http://www.wxqa.com/lum_search.htm.  A data report prepared at the six-year anniversary of the archive is at http://www.wxqa.com/lum_search.htm.

This repo is designed to present a parsing routine and invite contributions to its development, so to make the data archive 
truly available to all.  The initial commit is a routine that works, but rejects some stations as out of range or out of format which could actually be rescued with a bit more effort.  For example, one station records time as hhmmss rather than ddhhmm.  This data could be rescued by a programming change.  Another station uses commas as delimiters.  Its data is rejected by the initial parser; it could be rescued instead.  There are other examples.

What the parser does:

·         From each report it extracts the data nominally sent (station name, latitude, longitude, date, time of day, solar radiation measurement, some selection of meteorological variables, and a comment field describing hardware).

·         The parsing routine flags all data which lists dates more than a few hours from the limits of the daily archiving.  It rejects data that is more than a day away from the archive data.  

 ·         The parsing routine rejects latitudes and longitudes that are out of format.

·         For each observation, the parsing routine computes from latitude, longitude, day and time of day the corresponding solar zenith angle (in degrees), equation of time (in minutes) and the time of solar transit (JD).   These calculations draw on the insol routine of Javier Corripio.  These values enable automatic quality checking:  for example, bad clocks can be identified where we find reports of significant L where the zenith angle is more than 90 degrees from zero; daily maxima should occur on average at the time of solar transit, and so on.

·         For each observation, the parsing routine also identifies the elevation corresponding to the presented latitude and longitude.  This operates as a lookup.  In a separate file (latlonlist.txt) I have initially accumulated all the lat/lon combinations in the archive.  The user can update this using MakeLatLonList.R.  There are various ways to add the corresponding elevations.  I used gpsvisualizer.com.  The output of the lookup is at latlonelevation.txt.  The parser looks up each and every data point separately in that list, to find the elevation.  Yeah, that's slow programming.  The thing is, people carry their stations around, so you really can't assume much.

·         And on the basis of all of that (latitude, longitude, elevation, day, time of day, and frequently-available temperature and relative humidity) the parser then computes a modeled value of solar radiation (direct+diffuse).  Visibility is uniformly taken to be 90 km and albedo and ozone are taken constant.  This also draws on Corripio’s insol routine.  Again, this can serve as a quality check.

·         Finally, on the consideration that comparing modeled L to observed is excellent but since we have a quarter billion data points we don't want to do it by visual examination, the comparison is presented using a standard definition of attenuation of incoming radiation,  tau = - ln (i/i0).   

In sum, the repo is therefore initialized with five files:  

(1) startup.R which loads a few package and functions; it should go in the path and be sourced at outset.
(2) latlonlist.txt which is a list of all the latitude/longitude combinations in the dataset up to April 20, 2015.
(3) latlonelevation.txt which adds an elevation value to each lat/lon combination.  This lookup was undertaken at gpsvisualizer.com.  
(4) MakeLatLonList.R, the routine for updating latlonlist.txt to include newly-appearing stations or new locations of
old stations.  Note that the routine makes assumptions about where latlonlist.txt is stored, and where latlonelevation.txt should go.  
(5) parsecwopinsol.R, which sets out the parsing routine.  This also makes assumptions about where input data is stored,
where output data should go, and where to find latlonelevation.txt

It all could be more graceful.  Still I hope it is a help.



 
