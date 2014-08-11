function [ lat_min, lon_min, lat_max, lon_max ] = get_zoomed_coordinates_limits( viewer_handlers )
%GET_ZOOMED_COORDINATES_LIMITS Get coordinates limits of the region zoomed in/out. Lat should be [-90 90], Lon should be
%[-180 180], following SSH lat lon format
%   Detailed explanation goes here

if viewer_handlers.axisXLimit(1) <= viewer_handlers.mapXLimit(1)
    [lat_min, lon_min] = minvtran(viewer_handlers.mapXLimit(1), viewer_handlers.mapYLimit(1));    
else
    [lat_min, lon_min] = minvtran(viewer_handlers.axisXLimit(1), viewer_handlers.axisYLimit(1));
end

if viewer_handlers.axisXLimit(2) >= viewer_handlers.mapXLimit(2)
    [lat_max, lon_max] = minvtran(viewer_handlers.mapXLimit(2), viewer_handlers.mapYLimit(2));    
else
    [lat_max, lon_max] = minvtran(viewer_handlers.axisXLimit(2), viewer_handlers.axisYLimit(2));
end

end

