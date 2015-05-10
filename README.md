# solar-data-parser
A set of tools to make the archive of solar radiation data from the voluntary observers program (CWOP) available to all.

The NOAA-CWOP Solar Data archive, launched in February 2009,has accumulated a quarter billion observations of solar radiation from a global network of contributing weather stations.  Links to the archive can be found at http://www.wxqa.com/lum_search.htm.  A data report prepared at the six-year anniversary of the archive is at http://www.wxqa.com/lum_search.htm.

This repo presents a usable routine for parsing that data.  
The number of contributing stations has risen from about 800 to about 2500 thus far.  The network is global, concentrated in the US, Europe and Australia.  Most stations send accompanying met data.  Data sharing protocols indicate that the solar radiation sensor in use should be given within the body of the report.  In practice the sensors are not always named.  From data available it appears the Davis sensors predominate, but that may be an appearance due simply to the fact that the Davis sensors tend to ship with software that names the sensor.
 
Map, time series.
 
The archive is maintained by Russ Chadwick, ex-NOAA, and is publicly available via www.wxqa.com/**.  A data report prepared in February 2015 is available at *.
 
Some data comes from known sources, such as national meteorological agencies, but much is essentially crowd-sourced.  This calls for quality-checking in the case where meta-data is generally not available.  It is known that very many if not most stations are sited where they say they are, but in some cases, station managers provide latitude and longitude that is wrong, missing, not updated or out of format.  The coordinates cannot be quite trusted.    As for clocks, one has no reason a priori to trust them all.  The sensors themselves are thought to be good up to a few percent, based on manufacturer reports. 
 
To pick out stations reporting times and locations which are wrong or out of format, a data parsing routine has been prepared (and posted at Github under the project **), which does the following. 
 
·         From each report it extracts the data nominally sent (station name, latitude, longitude, date, time of day, solar radiation measurement, some selection of meteorological variables, and a comment field describing hardware).

·         The parsing routine flags all data which lists dates more than a few hours from the limits of the daily archiving.  It rejects as well latitudes and longitudes that are out of format.

·         To each value of latitude, longitude, day and time of day is associated the solar zenith angle, the equation of time, time of solar transit.   For this we used the insol routine of Javier Corripio.  Thus, for example, bad clocks are flagged by reports of significant L where abs(zenith angle) is larger than 90.

·         Also, with each measurement of L the database provides the modeled value of solar radiation (direct+diffuse) modeled on the basis of the given latitude, longitude, date, time of day, temperature, relative humidity, elevation and visibility uniformly taken to be 90 km.  Again this draws on Corripio’s insol.  Elevation is taken in all cases from the provided latitude and longitude, input to a DEM (thanks to ***) point by point.

·         Examination of modeled L compared to observed is one means to flags errors, but since we have a quarter billion data points we would rather not manage by examination.  Instead we compute the comparison at every point:  t = - ln (i/i0).   A given station’s anomalies can be compared to reasonable, representative distributions.  For example, station * is automatically found in this way to be anomalous; on examination, it is found that *.

 
