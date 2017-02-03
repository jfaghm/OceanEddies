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

