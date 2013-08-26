# OceanEddies
A collection of algorithms to autonomously identify and track mesoscale ocean
eddies in sea surface height (SSH) satellite data

## Eddyscan
An eddy identification algorithm that utilizes thresholding to detect eddies in
SSH data.

### Requirements
 + Matlab

### Example Usage
```matlab
% Find all anticyclonic eddies
ssh_slice = ncread('ssh_data.nc', 'Grid_0001');
landval = max(ssh_slice(:));
ssh_slice(ssh_slice == landval) = NaN;
lat = ncread('ssh_data.nc', 'NbLatitudes');
lon = ncread('ssh_data.nc', 'NbLongitudes');
lon(lon >= 180) = lon(lon >= 180)-360;
eddies = scan_single(ssh_slice, lat, lon, 'anticyc', 'v2');
```

## LNN
A tracking algorithm (surpassed by MHA) for eddies.

### Requirements
 + Matlab

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
command line respectively. Below is an example for using MHA in python.
```python
import mht

eddies_path = '/path/to/eddyscan/out'

roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), do_lookahead=True)
mht.write_tracks(roots, 'cyclonic_tracks.mat', mht.list_dates(eddies_path, 'eddies'))
```

## Eddy track viewer
This eddy viewer will display eddy tracks with the bodies borders layed on top of the ssh data.
It allows moving back and forth, and requires you to subset the data for performance (the subset
could consist of the entire world, but that would not give any performance boost).

### Requirements
 + Matlab

### Example Usage
```matlab
% Must have loaded ssh data, expects ssh, lat, lon, dates
% ssh should use NaNs for land

mk_global_data; % Need to modify script according to your setup
mk_all_subsets; % May need to modify. Which subsets are generated are in this file
load_and_plot('subsets/swpacific');
```
