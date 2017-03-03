Ocean Eddies Database
---------------------

### `eddies`

The `eddies` table contains information about all detected ocean eddies in the dataset.

|Column Name|Column Type|Description|
|-----------|-----------|-----------|
|`track_id` | `int`     |ID of an ocean eddy's track|
|`amplitude`| `float`   |Amplitude of the ocean eddy at a given point in time|
|`surface_area` | `float` | Surface area of the ocean eddy at a given point in time|
|`date` | `date` | Date that the eddy was detected |
|`cyc` | `int` | (Cyclonic = 1) or (Anti-Cyclonic = -1)|
|`mean_geo_speed` | `float` | Mean Geostrophic Speed|
|`geom` | `Geometry(POINT, 4326)` | Location information for the eddy|

### `storms`

The `storms` table contains information about hurricanes from the [HURDAT2](http://www.nhc.noaa.gov/data/) dataset.  This table includes both the Atlantic and Pacific hurricanes.

|Column Name|Column Type|Description|
|-----------|-----------|-----------|
|`index`|`int`|Unique identifier|
|`id`|`text`|ID assigned by NOAA|
|`name`|`text`|Name of the storem (Ex: Katrina) - Often `UNNAMED`|
|`date`|`timestamp`|Date of the record|
|`record_identifer`|`text`|A letter assigned to the record providing some additional context (see context table)|
|`status_of_system`|`text`|The type of storm (see Storm Types)|
|`geom` | `Geometry(Point, 4326)` | lat/lon point of the storm|
|`maximum_sustained_wind_knots` | `int` | The maximum 1-min average wind associated with the tropical cyclone at an elevation of 10 m with an unobstructed exposure, in knots (kt) |
|`maximum_pressure` | `int` | The central atmospheric pressure of the hurricane|
| `kt_ne_34` | `int` | This entry and those below it together indicate the boundaries of the storm's radius of maximum wind. 34 knots is considered tropical storm force winds, 50 knots is considered storm force winds, and 64 knots is considered hurricane force winds (source). These measurements provide the distance (in nautical miles) from the eye of the storm (its latitude, longitude entry) in which winds of the given force can be expected. This information is only available for observations since 2004. |  
| `kt_se_34` | `int` | "" | 
| `kt_sw_34` | `int` | "" | 
| `kt_nw_34` | `int` | "" | 
| `kt_ne_50` | `int` | "" | 
| `kt_se_50` | `int` | "" | 
| `kt_sw_50` | `int` | "" | 
| `kt_nw_50` | `int` | "" | 
| `kt_ne_64` | `int` | "" | 
| `kt_se_64` | `int` | "" | 
| `kt_sw_64` | `int` | "" | 
| `kt_nw_64` | `int` | "" | 

#### Context

|Code | Description|
|-------|------------|
|C | Closest approach to a coast, not followed by a landfall|
|G | Genesis|
|I | An intensity peak in terms of both pressure and wind|
|L | Landfall (center of system crossing a coastline)|
|P | Minimum in central pressure|
|R | Provides additional detail on the intensity of the cyclone when rapid changes are underway|
|S | Change of status of the system|
|T | Provides additional detail on the track (position) of the cyclone|
|W | Maximum sustained wind speed|

#### Storm Types
|Code | Description |
|-----|--------------|
|TD | Tropical cyclone of tropical depression intensity (< 34 knots)|
|TS | Tropical cyclone of tropical storm intensity (34-63 knots)|
|HU | Tropical cyclone of hurricane intensity (> 64 knots)|
|EX | Extratropical cyclone (of any intensity)|
|SD | Subtropical cyclone of subtropical depression intensity (< 34 knots)|
|SS | Subtropical cyclone of subtropical storm intensity (> 34 knots)|
|LO | A low that is neither a tropical cyclone, a subtropical cyclone, nor an extratropical cyclone (of any intensity)|
|WV | Tropical Wave (of any intensity)|
|DB | Disturbance (of any intensity)|