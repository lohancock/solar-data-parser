# solar-data-parser
Herewith a set of tools to make the archive of solar radiation data from the voluntary observers program (CWOP) available to all.

The NOAA-CWOP Solar Data archive, launched in February 2009,has accumulated a quarter billion observations of solar radiation from a global network of contributing weather stations.  The archive is comprised of daily archives, each a collection of reports gathered within a 24-hour period beginning at 11 PM UTC.  The number of contributing stations has risen from about 800 to about 2500 thus far.  The network is global, concentrated in the US, Europe and Australia.  Most stations send accompanying met data.  Links to the archive can be found at http://www.wxqa.com/lum_search.htm.  A data report prepared at the six-year anniversary of the archive is at http://www.wxqa.com/lum_search.htm.

This repo is designed to present and invite development of routines for parsing that data, so to make it 
truly available to all.

·         From each report it extracts the data nominally sent (station name, latitude, longitude, date, time of day, solar radiation measurement, some selection of meteorological variables, and a comment field describing hardware).

·         The parsing routine flags all data which lists dates more than a few hours from the limits of the daily archiving.  It rejects as well latitudes and longitudes that are out of format.

·         To each value of latitude, longitude, day and time of day is associated the solar zenith angle, the equation of time and the time of solar transit.   For this we used the insol routine of Javier Corripio.  Thus, for example, bad clocks can be identified where we find reports of significant L where the zenith angle is more than 90 degrees from zero.

·         Also, with each measurement of L the database provides the modeled value of solar radiation (direct+diffuse) modeled on the basis of the given latitude, longitude, date, time of day, temperature, relative humidity, elevation and visibility uniformly taken to be 90 km.  Again this draws on Corripio’s insol.  Elevation is taken in all cases from the provided latitude and longitude, input to a DEM (http://www.gpsvisualizer.com/) point by point.

·         Examination of modeled L compared to observed is one means to flags errors, but since we have a quarter billion data points we would rather not manage by examination.  To facilitate statistical comparisons, each measurement is also accompanied by a value for attenuation of incoming radiation,  tau = - ln (i/i0).   

The repo is therefore initialized with five files:  

(1) startup.R which loads a few package and functions;
(2) latlonlist.txt which is a list of all the latitude/longitude combinations in the dataset up to April 20, 2015.
(3) latlonelevation.txt which adds an elevation value to each lat/lon combination.  This lookup was undertaken at gpsvisualizer.com
(4) MakeLatLonList.R, the routine for updating latlonlist.txt to include newly-appearing stations or new locations of
old stations.  Note that the routine makes assumptions about where data is stored; you would likely wish to change these.
(5) parsecwopinsol.R, which sets out the parsing routine.  This one also makes assumptions about where input data is stored,
where output data should go, and where to find latlonelevation.txt

It all could be more graceful.  Still I hope it is a help.



 
