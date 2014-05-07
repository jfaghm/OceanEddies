function [plot_handle, current_data] = plot_background_data( hdls, background_data, lat, lon )
%PLOT_BACKGROUND_DATA Plot background with given background_data and lat lon

current_data = background_data;

if hdls.is_autoadjusting_background
    % The auto adjustment toggle button is on
    % Set min and max by current region
    
    % Make lon going from -180 to 180
    lon(lon < -180) = lon(lon < -180) + 360;
    lon(lon > 180) = lon(lon > 180) - 360;
    
    % Get coordinates of zoomed region
    [lat_min, lon_min, lat_max, lon_max] = get_zoomed_coordinates_limits( hdls );
    
    lat_index = lat >= lat_min & lat <= lat_max;
    if lon_max > lon_min
        lon_index = lon >= lon_min & lon <= lon_max;
    elseif lon_max < lon_min
        % The case when lon min -> 180 (-180) -> lon_max
        lon_index = lon >= lon_min | lon <= lon_max;
    else
        % The whole map
        lon_index = ~isnan(lon);
    end
    
    region_of_interest = background_data(lat_index, lon_index);
    min_value = min(region_of_interest(:));
    max_value = max(region_of_interest(:));
    if ~isnan(min_value)
        hdls.minBackgroundValue = min_value;
    else
        hdls.minBackgroundValue = -inf;
    end
    if ~isnan(max_value)
        hdls.maxBackgroundValue = max_value;
    else
        hdls.maxBackgroundValue = inf;
    end 
end

current_data(current_data <= hdls.minBackgroundValue) = hdls.minBackgroundValue;
current_data(current_data >= hdls.maxBackgroundValue) = hdls.maxBackgroundValue;

colormap(jet);

plot_handle = pcolorm(lat, lon, current_data);

end