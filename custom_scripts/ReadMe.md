# Custom Scripts to extend functionality of OceanEddies software
*This ReadMe.md belongs to **custom_scripts** directory*

## Author
Ramkrushnbhai S. Patel $^{1,2}$

1: [Institute for Marine and Antarctic Studies](https://www.imas.utas.edu.au), [University of Tasmania](https://www.utas.edu.au), Hobart, Tasmania, Australia

2: [Australian Research Council Centre of Excellence for Climate Extremes](https://climateextremes.org.au), University of Tasmania, Hobart, Tasmania, Australia

## ABOUT
The *custom_scripts* directory provides the scripts that automatise the detection and tracking of eddies using Faghmous et al. 2015 software.  
## CONTENTS
Directory | Description
--------- | ----------
custom_scripts | Collection of preprossing, post-processing and analyses scripts
txt file | global coastline data
ReadMe | -

### Example scripts
*AutomateEntireSoft.m* : demonstrates how to automate the software from altimetry data\
*idealizedmodelautomate.m* : demonstrates how to automate the software from idealised model output data\
*EddyAnimation.m* : makes movie to identify specific types of eddies\


### Preprocessing functions
*set_up_NRTdata_regional.m* : prepares near-real-time daily SLA maps for the software\
*set_up_DTdata_regional.m* : prepares delay-mode daily SLA maps for the software with modified area-map algorithm\
*set_up_data_3D2daily.m* : converts 3D.mat file to daily to conform complete_run.m function input\
*set_up_data_3D2dailyModel.m* : flexible compare to 3D2daily function\
**

### Supporting functions
*plotTrack.m* : visualise eddies track redily after the detection for the quick summary

### Contact
If you have any question or feedback, please raise an issue in [OceanEddiesToolbox](https://github.com/rampatels/OceanEddiesToolbox.git) repository.