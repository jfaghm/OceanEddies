function [ eddies ] = bottom_up_single(ssh_data, lat, lon, areamap, cyc, varargin)
%BOTTOM_UP_SINGLE Finds eddies using the Bottom Up method
%   Will return an array of struct's that contain the eddy data.
%   ssh_data: A 2D array of double's that contain the sea surface heights (latsxlons)
%   lat: A 1D array of double's that gives the latitude for a given index (dimension should match
%         that of ssh_data)
%   lon: A 1D array of double's that gives the longitude for a given index (dimension should match
%         that of ssh_data)
%   areamap: A 2D array that refer to the area of each pixel in SSH data (should have same size as ssh), or 1D array 
%   that refer to area of each pixel for a specific lat in a regular grid (pixeld have same area for the same 
%   latitude)
%   cyc: Pass 1 to output anticyclonic eddies or -1 to output cyclonic eddies
%   Optional parameters:
%   'minimumArea': minimum number of pixels for an eddy, used for validating eddies
%   'thresholdStep': the minimum step for thresholding, the unit is SSH's unit
%   'isPadding': whether or not to pad SSH data, should be true when scanning SSH data of the whole map. Set to false if
%   only partial SSH data is used.
%   'sshUnits': The units the SSH data is in. bottom_up_single is built to work natively on centimeter SSH data.
%   Valid parameters are 'meters' and 'centimeters'. If the paramater passed in is 'meters', the SSH data will
%   be multiplied by 100. No changes will be made if the paramater passed in is 'centimeters'.
%   The default value of 'sshUnits' is centimeters.
    p = inputParser;
    defaultMinPixelSize = 9;
    defaultThresholdStep = 0.05;
    defaultSSHUnits = 'centimeters';
    defaultPaddingFlag = true;
    addRequired(p, 'ssh_data');
    addRequired(p, 'lat');
    addRequired(p, 'lon');
    addRequired(p, 'areamap');
    addRequired(p, 'cyc');
    addParameter(p, 'minimumArea', defaultMinPixelSize, @isnumeric);
    addParameter(p, 'thresholdStep', defaultThresholdStep, @isnumeric);
    addParameter(p, 'isPadding', defaultPaddingFlag);
    addParameter(p, 'sshUnits', defaultSSHUnits);
    parse(p, ssh_data, lat, lon, areamap, cyc, varargin{:});
    minimumArea = p.Results.minimumArea;
    thresholdStep = p.Results.thresholdStep;
    isPadding = p.Results.isPadding;
    SSH_Units = p.Results.sshUnits;
    
    if strcmp(SSH_Units, 'meters')
        ssh_data = ssh_data * 100;
    elseif strcmp(SSH_Units, 'centimeters')
        max_val = max(ssh_data(:));
        min_val = max(ssh_data(:));
        if max_val < 1 && min_val > -1
            ssh_data = ssh_data * 100;
        elseif max_val < 100 && min_val > -100
        
        else
            error('Could not figure out what units the SSH data provided is in. Please specify it as an additional parameter: sshUnits');
        end
    end

    %Check if the grid is regular (differences between lats and lons are equal)
    lat_diffs = lat(2:end) - lat(1:end-1);
    lat_diffs2 = lat_diffs(2:end) - lat_diffs(1:end-1);
    lon_diffs = lon(2:end) - lon(1:end-1);
    lon_diffs(lon_diffs <= -180) = lon_diffs(lon_diffs <= -180) + 360;
    lon_diffs(lon_diffs >= 180) = lon_diffs(lon_diffs >= 180) - 360;
    lon_diffs = abs(lon_diffs);
    lon_diffs2 = lon_diffs(2:end) - lon_diffs(1:end-1);
    if all(lat_diffs2 == 0) && all(lon_diffs2 == 0)
        % Regular grid, create a georasterref object to get eddy's centroid
        geo_raster_lat_limit = [lat(1) lat(end)];
        if lon(1) > lon(end)
            geo_raster_lon_limit = [lon(1) (360 + lon(end))];
        else
            geo_raster_lon_limit = [lon(1) lon(end)];
        end

        R = georasterref('LatLim', geo_raster_lat_limit, 'LonLim', geo_raster_lon_limit, 'RasterSize', ...
         size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');
    else
        % Use normal indexing to get eddy's centroid
        R = [];
    end
    
    extrema = get_extrema(ssh_data, cyc);
    
    if isPadding
        origExtrema = extrema;
        extrema = [zeros(size(extrema, 1), 200), extrema, zeros(size(extrema, 1), 200)];
        sshExtended = [ssh_data(:, end-199:end), ssh_data(:, :), ssh_data(:, 1:200)];
        [extrema_lat_indexes, extrema_lon_indexes] = ind2sub(size(extrema), find(extrema == 1));

        extrema(:, 1:200) = origExtrema(:, end-199:end);
        extrema(:, end-199:end) = origExtrema(:, 1:200);
    else
        [extrema_lat_indexes, extrema_lon_indexes] = ind2sub(size(extrema), find(extrema == 1));
        sshExtended = ssh_data;
    end
        

    eddies = new_eddy();
    eddies(length(extrema_lat_indexes)).Date = NaN;
    cyc_sshExtended = sshExtended * cyc;
    parfor i = 1:length(extrema_lat_indexes)
        curr_lat_index = extrema_lat_indexes(i); curr_lon_index = extrema_lon_indexes(i);
        e = thresholdBU(cyc, curr_lat_index-5, curr_lat_index+5, curr_lon_index-5, curr_lon_index+5, ...
            sshExtended, extrema, curr_lat_index, curr_lon_index, sshExtended(curr_lat_index, curr_lon_index), ...
            thresholdStep, NaN, ...
            zeros(size(sshExtended)), lat, lon, R, areamap, minimumArea, isPadding, cyc_sshExtended);
        if ~isempty(e)
            eddies(i) = e;
        end
    end
    mask = cellfun('isempty', {eddies.Lat});
    eddies = eddies(~mask);
end
