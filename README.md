# OceanEddies
A collection of algorithms to autonomously identify and track mesoscale ocean
eddies in sea surface height (SSH) satellite data. For immediate support email Ivy Frenger (ifrenger@geomar.de, see also  https://github.com/ifrenger/OceanEddies).

## Eddyscan
An eddy identification algorithm that utilizes thresholding to detect eddies in
SSH data.

### Requirements
 + Matlab

### Usage
There are two scripts which can be used to call eddyscan: [scan_single.m](eddyscan/scan_single.m)
and [scan_multi.m](eddyscan/scan_multi.m). The second script is can be used to scan many
timesteps at once. Below is an example for using ``scan_single.m`` (assuming current directory is eddyscan):
```matlab
% Find all anticyclonic eddies
ssh_slice = ncread('ssh_data.nc', 'Grid_0001');
landval = max(ssh_slice(:));
ssh_slice(ssh_slice == landval) = NaN;
lat = ncread('ssh_data.nc', 'NbLatitudes');
lon = ncread('ssh_data.nc', 'NbLongitudes');
lon(lon >= 180) = lon(lon >= 180)-360;
load('../data/quadrangle_area_by_lat.mat'); % Load areamap to compute eddies' surface areas
eddies = scan_single(ssh_slice, lat, lon, 'anticyc', 'v2', areamap);
```
## `scan_single(ssh,lat,lon,areamap,cyc,scan_type,...)`

Detect all eddies for a particular timestamp.

##### Required arguments

1. `ssh` - ssh slice with nans for land, size should be `[length(lat) length(lon)]`
2. `lat` - 1D array of the latitudes of ssh grid
3. `lon` - 1D array of the longitudes of ssh grid
4. `cyc` - `'anticyc'` or `'cyclonic'`
5. `scan_type` -  `'v1'`, `'v2'`, `'hybrid'`
  - v1: Will run top-down scanning (only works with full data of 0.25 x 0.25 ssh grid)
  - v2: Will run bottom-up scanning from the minima of the field
  - hybrid: Will run `v2` and `v1` scanning and will take the union of the two sets where, for common features, `v2` bodies will be used
6. `areamap` - A 2D array that refer to the area of each pixel in SSH data (should have same size as ssh), or 1D array that refer to area of each pixel for a specific lat in a regular grid (pixeld have same area for the same latitude)

##### Optional parameters (only applicable for v2 eddyscan):

1. `'minimumArea'` - minimum number of pixels for an eddy, used for validating eddies, default value is `9`
2. `'thresholdStep'` - the minimum step for thresholding, the unit is SSH's unit, default value is `0.05`
3. `'isPadding'` - whether or not to pad SSH data, should be true when scanning SSH data with the longitudes expanding the whole world dmap. Set to false if only partial SSH data is used. Default value is true
4. `'sshUnits'` -  The units the SSH data is in. bottom_up_single is built to work natively on centimeter SSH data.  Valid parameters are `'meters'` and `'centimeters'`. If the paramater passed in is `'meters'`, the SSH data will be multiplied by 100. No changes will be made if the paramater passed in is `'centimeters'`.  The default value of 'sshUnits' is centimeters.

## `scan_multi(ssh,lat,lon,areamap,cyc,scan_type,destdir,...)`

Detect all eddies for all time steps.  Results are saved to disk as specified by the `destdir` paramter.

##### Required arguments

1. `ssh` - ssh cube with nans for land
2. `lat` - A 1D array of double's that gives the latitude for a given index in ssh data , should be equal to `size(ssh, 1)`
3. `lon` - A 1D array of double's that gives the longitude for a given index in ssh data, should be equal to `size(ssh, 2)`
4. `dates` - A 1D array of the dates of ssh data, length should be equal to `size(ssh, 3)`
5. `cyc` - `'anticyc'` or `'cyclonic'`
6. `scan_type` - `'v1'`, `'v2'`, `'hybrid'`
  - v1: Will run top-down scanning
  - v2: Will run bottom-up scanning from the minima of the field
  - hybrid: Will run `v2` and `v1` scanning and will take the union of the two sets where, for common features, `v2` bodies will be used
7. `destdir` - destination directory to save eddies

##### Optional parameters:

Same as `scan_single`


## LNN
A tracking algorithm (surpassed by MHA) for eddies.

### Requirements
 + Matlab

### Usage
See [track_lnn.m](track_lnn.m).

## MHA
A tracking algorithm that maintains multiple hypothesis and does n-scan pruning.
MHA can allow eddies to disappear for one timestep from the data to avoid breaking tracks.

### Requirements
 + Python
 + Cython
 + Scipy
 + Numpy

### Build
To build MHA, run ``python setup.py build_ext -b mht`` in [mha/](mha/).

### Example Usage
MHA can be called from within MATLAB, the command line, or python. See
[track_mha.m](mha/track_mha.m) and [track_mha.py](mha/track_mha.py) for running from MATLAB or the
command line respectively. Below is an example for using MHA in python:
```python
import mht

eddies_path = '/path/to/eddyscan/out'

roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), do_lookahead=True)
mht.write_tracks(roots, 'cyclonic_tracks.mat', mht.list_dates(eddies_path, 'eddies'))
```

## Eddy track viewer
This eddy viewer will display eddy tracks from Eddyscan v2 together with SSH data background. It contains the following components (from left to right, top to bottom):
- Current date textbox: a textbox that displays current date
- Eddy type checkboxes: for choosing which type of eddies to display (cyclonic/anticyclonic). User can also choose to display both of them on the world map.
- Track type dropdown box: for choosing different type of tracks to display, for now the script only sets up All or None.
- Track filter by length: user can input minimum and maximum length (lifetime) of displayinig tracks, leave blank or 'any' if you want to see tracks with any length.
- Background dropbox: a dropbox for choosing type of background to display on world map. For now the script only let the user choose either None or SSH background.
- Show contours toggle button: Toggle this button for turning on/off the bodies borders of current eddies on world map.
- Show Chelton tracks toggle button: Toggle this button for turning on/off Chelton tracks from http://cioss.coas.oregonstate.edu/eddies/data.html.
- Select eddy button: pressing this button will let the user select a current eddy and view its information in the eddy info textbox.
- Date list box: a list of dates in yyyymmdd format will be displayed for user to select so that only tracks that have one eddy detected at that selected date will be displayed on world map.
- World map: display background and qualified tracks on the map. Current eddies will be filled with the corresponding color in the legend. Eddies in the past will be on green path, and eddies in the future will be on paths with different colors as the legend shows. Any change of the above components will update world map.
- Forward/Backward button: move the time forward or backward and update world map.
- Eddy info text box: display the information of the eddy selected after clicking select eddy button.

Currently, only a sample data set of the first 12 weeks (10/14/1992 to 12/30/1992) is uploaded on Github. Full viewer data (about 3GB) are available at http://gofc.cs.umn.edu/eddy_project/tracks_viewer_data.zip. Use prepare_viewer_data to download and unzip data.

### Requirements
 + Matlab Mapping Toolbox

### Example Usage
```matlab
start_track_viewer; % This script will start the viewer with sample data (first 12 weeks)
```
