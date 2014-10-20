README for eddyscan_compiled_script:

Files that you may need to generate by yourself:
Our eddyscan code requires a parameter that is called "area_map".
This parameter is an area map of area values of a grid that represents the
Earth. Because the Earth is round, values in this map are largest at the
equator, and smallest at the poles. This area map is just a 1-D array
of values for different latitudes, but the size of the area map array must
match the size of the latitude in the SSH data.
Example: SSH data is provided as a 720x1440 array (720 is latitude, 1440 is
longitude). The area map must be a length of 720 values.

Because SSH data can come in different sizes, the area_map must be re-created
if the SSH data being scanned is a different size than 720x1440. Longitude
length changes matter as well. Although the area map will still remain the
same length, the values in the area map will change based on changes to the
longitude length.

Eddyscan can be run without this area_map parameter, it's not necessary to get
eddies, but if this parameter is not specified correctly the area values
that scanned eddies have will be meaningless junk. Everything else in the
eddy data will be fine.

We provide a function "generate_area_map" for you to generate a new area map
based on whatever latitude and longitude sizes your SSH grid is in.
Example:
area_map = generate_area_map(720, 1440);
Where 720 is the latitude size, and 1440 is the longitude size.

Usage Notes:
To run the compiled version of the eddyscan code, MATLAB's MCR
(MATLAB Compiler Runtime) is required to be installed on the host machine.
MCR is a free download provided by MathWorks at
http://www.mathworks.com/products/compiler/mcr/

This code was compiled with MATLAB R2014a, so it is suggested that MCR
version 8.3 is used to run the code.

SSH data is assumed to be in .nc files. Our code uses MATLAB's built in
ncread() function to extract the SSH, latitude, and longitude data from the
.nc file.

IMPORTANT: How to structure your SSH data to use our code:
A specific directory structure is required for this code to work.
The directory hierarchy is as follows:
There must be one main directory where all SSH data is stored. Inside of this
directory there should be sub-directories that actually contain the SSH data.
An example:
SSH_Data/
-1993/
--dt_global_allsat_msla_h_19930101_20140106.nc
--dt_global_allsat_msla_h_19930102_20140106.nc
--dt_global_allsat_msla_h_19930103_20140106.nc
--dt_global_allsat_msla_h_19930104_20140106.nc
-1994/
--dt_global_allsat_msla_h_19940101_20140106.nc
--dt_global_allsat_msla_h_19940102_20140106.nc
--dt_global_allsat_msla_h_19940103_20140106.nc
--dt_global_allsat_msla_h_19940104_20140106.nc

In this example, SSH_Data/ is the main directory, 1993/ and 1994/ are the
sub-directories, and all of the dt_global... files are the SSH .nc files.

This structure comes from the directory structure that AVISO+ uses when
it distributes its SSH data. Data is stored in sub-directories based on which
year the data is from, so this program looks for the same data structure
when it goes to scan SSH data for eddies.

Improperly structured SSH directories will fail to be scanned by the 
unmodified eddyscan we provide.

How to run:
To run the compiled version of the eddyscan code, the file
"run_eddyscan_compiled_script.sh" must be run with a few arguments.

General case:
./run_eddyscan_compiled_script <MCR-absolute-path> sub-directory/filename
absolute-path-to-main-directory absolute-path-to-save-directory

An example of using "run_eddyscan_compiled_script.sh":
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/

Argument breakdown:
"/arbitrary/path/here/MCR/v83/"
This is: <MCR-absolute-path>
This argument is the path to the MCR installed on your host machine.
Depending on your MCR version, MCR may or may not be in directory "v83/"

"2004/dt_global_allsat_msla_20040101_20140106.nc"
This is: sub-directory/filename
This argument is technically the file name argument, though this argument can
be broked into two parts:
"2004/"
The sub-directory (see 2nd section of the README on how to structure your
SSH directory) where that year's SSH data files are stored.
"dt_global_allsat_msla_20040101_20140106.nc"
The actual file name. File names may vary.

"/arbitrary/ssh_data/path/"
This is: absolute-path-to-main-directory
This is the path to your SSH data main directory (in the example in section 2,
the main directory would be SSH_Data/, which would be the last directory
specified in this argument)

"/arbitrary/save/path/"
This is: absolute-path-to-save-directory
This is the save path of where you want detected eddies to be saved. The
specified directory will be used as a main eddy directory, and eddies will
be saved in sub-directories that are named based on the names of the
sub-directories in the SSH data main directory.
Example: If SSH_Data/ has sub-directory 1993/ scanned, the results will be
saved inside a sub-directory named 1993/ that will reside in the main
directory specified by the arbitrary save path.

Optional Arguments:
Our eddyscan code allows the scan's parameters to be modified per run. This
section will teach the user what each of the optional arguments is, how to
set them in calling the comiled script, and their impact on the scan. The
optional arguments that can be specified by the user are as follows:

minimumArea (Minimum Area):
Minimum area defaults to 9 pixels when unspecified.
This argument sets the minimum area that an eddy can have to be classified as
an eddy. The value specified for this parameter is an integer, and it is
actually based on the number of pixels that the eddy consists of.
E.G. An eddy is detected and takes up a total area of 25 pixels on the SSH
grid. The minimum area is set to 9 pixels, so the eddy passes this check and
continues on in the scan. Say another eddy with a total pixel count of 5 is
detected. It would fail this check and not be considered an eddy.

To specify this argument, after providing the required arguments (MCR
directory, file name, file path, save path), pass "minimumArea" without
quotes, followed by the value you want minimumArea to be set to.
E.G.
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/ minimumArea 4

thresholdStep (Threshold Step):
Threshold step defaults to 0.05 when unspecified.
This argument will set the threshold step that the scan will change by between
each scan of the SSH grid. An understanding of the original eddyscan
algorithm (from Chelton et al.) is required to completely understand
the impact of changing the thresholdStep, but a high level explanation is
that as the threshold step gets larger, only the most prominent eddies are
detected. Conversely, the smaller the threshold step gets, the more the smaller
and less prominent eddies will begin to show up in scans alongside the most
prominent eddies. These less prominent eddies can give good information about
relatively calm spots on the ocean, but these smaller eddies are also more
prone to significant impact from noise in the data, or other environmental
noise. False eddies begin to show up more as the threshold step gets smaller
as well. Small eddies are important, but they usually need more verification
to be proven not to be false.

To specify this argument, after providing the required arguments (MCR
directory, file name, file path, save path), pass "minimumArea" without
quotes, followed by the value you want minimumArea to be set to.
E.G.
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/ thresholdStep 0.05

isPadding (Is Padding):
Is padding defaults to true when unspecified.
This argument specifies whether the eddyscan code will pad the right and left
sides of the SSH grid so that eddies detected right on the edge of the grid
will not be duplicated on both sides of the grid. There is almost never a
reason to set this flag to false, but it can be done should the need arise.

To specify this argument, after providing the required arguments (MCR
directory, file name, file path, save path), pass "minimumArea" without
quotes, followed by the value you want minimumArea to be set to.
E.G.
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/ isPadding true

sshUnits (SSH units):
SSH units defaults to centimeters when unspecified.
This argument will modify the SSH grid by multiplying or dividing the entire
matrix until the max value is near 100 and the min value is near -100. This
is done for continuity among different formats of SSH data (old weekly data
came in units of centimeters, not daily data comes in units of meters) so
that there is no difference between scans of different units. This is done
for the internal workings of our eddyscan. Eddy results will not be completely
correct unless this parameter is specified properly, but the code also
attempts to detect the units of the SSH Grid automatically, and will
change its copy of the grid accordingly. Meter and centimeter are the only two
untis that our lab has come across for SSH Data, so those are currently the
only two supported.

To specify this argument, after providing the required arguments (MCR
directory, file name, file path, save path), pass "minimumArea" without
quotes, followed by the value you want minimumArea to be set to.
E.G.
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/ sshUnits meters

General Case of optional arguments:
The general case for specifying these is very simple. After specifying all
required arguments, simply type the name of the optional argument that
you want to specify, and then type it's value afterward.
E.G. argument_name argument_value

A full run of optional arguments (Didn't bother specifying isPadding):
./run_eddyscan_compiled_script /arbitrary/path/here/MCR/v83/ 2004/dt_global_allsat_msla_20040101_20140106.nc /arbitrary/ssh_data/path/ /arbitrary/save/path/ minimumArea 4 thresholdStep 0.05 sshUnits meters
