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

## MHA
A tracking algorithm that maintains multiple hypothesis and does n-scan pruning.
MHA can allow eddies to disappear for one timestep from the data to avoid breaking tracks.

### Requirements
 + Python
 + Cython
 + Scipy

### Build
To build MHA, run ``python setup.py build_ext -b mht``

### Example Usage
```python
import mht

eddies_path = '/path/to/eddyscan/out'

roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), do_lookahead=True)
mht.write_tracks(roots, 'cyclonic_tracks.mat', mht.list_dates(eddies_path, 'eddies'))
```

### Exporting
To convert data from the representation used by MHA to a two dimensional table
format, use ``mha_export``. Note that this requires MATLAB to run.
