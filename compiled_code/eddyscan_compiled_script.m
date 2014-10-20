function eddyscan_compiled_script(file_name, file_path, save_path, varargin)%#codegen
if ~strcmp(file_path(end), '/')
    file_path = strcat(file_path, '/');
end
if ~strcmp(save_path(end), '/')
    save_path = strcat(save_path, '/');
end
vars = load('area_map.mat');
area_map = vars.area_map;
[dir, rem] = strtok(file_name, '/');
filename = strtok(rem, '/');
eddy_dir = [save_path, dir];
indices = regexp(filename, '[0-9]');
nums = filename(indices);
date = nums(1:8);
eddy_file = ['anticyc_', date, '.mat'];
if exist(eddy_dir, 'dir')
    cd(eddy_dir);
    if exist(eddy_file, 'file')
        disp('Eddy file detected, quitting.');
        %quit;
    end
end
cd([file_path, dir]);
if exist([file_path, dir, '/', filename], 'file') && ~exist([save_path, dir, '/', eddy_file], 'file')
    ssh = ncread(filename, 'sla')';
    lat = double(ncread(filename, 'lat'));
    lon = double(ncread(filename, 'lon'));
    cd(save_path);
    ant_eddies = scan_single(ssh, lat, lon, date, 'anticyc', 'v2', area_map, varargin{:});%#ok
    cyc_eddies = scan_single(ssh, lat, lon, date, 'cyclonic', 'v2', area_map, varargin{:});%#ok
    if ~exist([save_path, dir], 'dir')
        mkdir([save_path, dir]);
    end
    cd([save_path, dir]);
    save(['anticyc_', date, '.mat'], 'ant_eddies');
    save(['cyclonic_', date, '.mat'], 'cyc_eddies');
else
    
end
%quit;
end

function [ eddies ] = scan_single( ssh, lat, lon, date, cyc, scan_type, areamap, varargin )
%SCAN_SINGLE Wrapper function to do scanning
% ssh: ssh slice with nans for land, size should be [length(lat) length(lon)]
% lat: 1D array of the latitudes of ssh grid
% lon: 1D array of the longitudes of ssh grid
% cyc: 'anticyc' or 'cyclonic'
% scan_type: 'v1', 'v2', 'hybrid'
%         v1: Will run top-down scanning (only works with full data of 0.25 x 0.25 ssh grid)
%         v2: Will run bottom-up scanning from the minima of the field
%     hybrid: Will run v2 and v1 scanning and will take the union of the
%             two sets where, for common features, v2 bodies will be used
% areamap: A 2D array that refer to the area of each pixel in SSH data (should have same size as ssh), or 1D array 
%   that refer to area of each pixel for a specific lat in a regular grid (pixeld have same area for the same 
%   latitude)
% Optional parameters (only applicable for v2 eddyscan):
%   'minimumArea': minimum number of pixels for an eddy, used for validating eddies, default value is 9
%   'thresholdStep': the minimum step for thresholding, the unit is SSH's unit, default value is 0.05
%   'isPadding': whether or not to pad SSH data, should be true when scanning SSH data with the longitudes expanding the 
%   whole world dmap. Set to false if only partial SSH data is used. Default value is true
    if ~any(isnan(ssh(:)))
        error('Invalid ssh data, must contain NaNs for land values');
    end

    if ~all(size(ssh) == [length(lat) length(lon)])
        error('Invalid ssh data size, should be [length(lat) length(lon]');
    end
    
    if ~all(size(areamap) == size(ssh))
        % Not a 2d array with same size as ssh
        if ~any(size(areamap) == [1 1]) || length(areamap) ~= length(lat)
            disp('Invalid areamap, using NaN for eddy surface area');
        end
    end
    
    stype = get_stype(scan_type);
    ctype = get_ctype(cyc);
    disp('About to start scanning eddies');
    
    %oldpath = addpath('lib');
    switch stype
        case 1
            eddies = top_down_single(ssh, lat, lon, areamap, ctype, varargin{:});
        case 2
            eddies = bottom_up_single(ssh, lat, lon, areamap, ctype, varargin{:});
%        case 0
%            scanners = {@top_down_single, @bottom_up_single};
%            eddies_out = {[], []};
%            parfor i = 1:2
%                eddies_out{i} = scanners{i}(ssh, lat, lon, areamap, ctype, varargin{:});
%            end
%            eddies = get_combined_eddy_frames(eddies_out{2}, eddies_out{1}, ssh);
    end
    [eddies.Date] = deal(date);
    
    %path(oldpath);
   
end
%end

function cyc_t = get_ctype(cyc)
    switch cyc
        case 'anticyc'
            cyc_t = 1;
        case 'cyclonic'
            cyc_t = -1;
        otherwise
            error('cyc must be anticyc or cyclonic');
    end
end

function scan_t = get_stype(scan_type)
    switch scan_type
        case 'v1'
            scan_t = 1;
        case 'v2'
            scan_t = 2;
        case 'hybrid'
            scan_t = 0;
        otherwise
            error('scan_type must be v1, v2, or hybrid');
    end
end

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
    addParameter(p, 'minimumArea', defaultMinPixelSize);%, @isnumeric);
    addParameter(p, 'thresholdStep', defaultThresholdStep);%, @isnumeric);
    addParameter(p, 'isPadding', defaultPaddingFlag);
    addParameter(p, 'sshUnits', defaultSSHUnits);
    parse(p, ssh_data, lat, lon, areamap, cyc, varargin{:});
    minimumArea = p.Results.minimumArea;
    thresholdStep = p.Results.thresholdStep;
    isPadding = p.Results.isPadding;
    SSH_Units = p.Results.sshUnits;
    disp(minimumArea);
    if isa(minimumArea, 'char')
        disp('Minimum area was a string, converting to double.');
        minimumArea = str2double(minimumArea);
        disp(minimumArea);
    end
    if isa(thresholdStep, 'char')
        disp('Threshold step was a string, converting to double.');
        thresholdStep = str2double(thresholdStep);
        disp(thresholdStep);
    end
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
    disp('About to get extrema');
    
    extrema = get_extrema(ssh_data, cyc);
    disp('Got extrema');
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
        
    disp('Scanning');
    eddies = new_eddy();
    eddies(length(extrema_lat_indexes)).Date = NaN;
    cyc_sshExtended = sshExtended * cyc;
    parfor i = 1:length(extrema_lat_indexes) % Normally a parfor. Modified to a for loop solely for itasca testing
        curr_lat_index = extrema_lat_indexes(i); curr_lon_index = extrema_lon_indexes(i);
        e = thresholdBU(cyc, curr_lat_index-5, curr_lat_index+5, curr_lon_index-5, curr_lon_index+5, ...
            sshExtended, extrema, curr_lat_index, curr_lon_index, sshExtended(curr_lat_index, curr_lon_index), ...
            thresholdStep, NaN, ...
            zeros(size(sshExtended)), lat, lon, R, areamap, minimumArea, isPadding, cyc_sshExtended);
        %disp(e);
        if ~isempty(e.Stats)
            %disp(['Adding eddy at index: ', num2str(i)]);
            %disp(e);
            eddies(i) = e;
        end
    end
    %lat_array = [eddies.Lat];
    %disp(lat_array);
    mask = false(1, length(eddies));
    for i = 1:length(eddies)
        if isempty(eddies(i).Lat)
    %        disp(['Empty lat array index at ', num2str(i)]);
            mask(i) = true;
        end
    end
    disp('Scanned');
    %mask = cellfun('isempty', {eddies.Lat});
    eddies = eddies(~mask);
    %lat_array = [eddies.Lat];
    %disp(lat_array);
end

function [eddy] = thresholdBU(cyc, block_bottom_index, block_top_index, block_left_index, block_right_index, ...
        ssh, extrema, extrema_lat_index, extrema_lon_index, thresh, threshold_step, last_step, previous, ...
        lat, lon, R, areamap, min_pixel_size, is_padding, cyc_ssh)
% THRESHOLDBU Get an eddy by bottom up method
%   cyc: 1 for anticyclonic and -1 for cyclonic
%   block_bottom(top/left/right)_index: index of the bottom/top/left/right of the block that will be used for
%   thresholding
%   ssh: ssh data(extended if is_padding is true)
%   extrema: logical index of ssh extrema
%   extrema_lat/lon_index: lat/lon index of the extremum that is being used to find an eddy
%   thresh: current threshold that is being used to find an eddy
%   threshold_step: the step to increase/decrease threshold value, based on eddy type
%   last_step: the last step was used for thresholding
%   previous: 2d logical array of the connected component that contains the extremum in the last thresholdBU call
%   lat: 1d array of latitudes of the ssh grid
%   lon: 1d array of longitudes of the ssh grid
%   R: the georasterref object for SSH grid
%   areamap: 1D or 2D array of reference to area of each pixel in SSH grid
%   min_pixel_size: minimum number of pixels for an eddy
%   is_padding: whether or not the SSH data is padded
    
    switch cyc
        case 1
            intensity = 'MaxIntensity';
        case -1
            intensity = 'MinIntensity';
        otherwise
            error('Invalid cyc');
    end

    if block_bottom_index < 1 || block_top_index > size(ssh, 1) || ...
            block_left_index < 1 || block_right_index > size(ssh, 2)
        edgeOfWorld = true;
        
        while block_bottom_index < 1 || block_top_index > size(ssh, 1) || ...
            block_left_index < 1 || block_right_index > size(ssh, 2)
            % Make sure that the block is inside the grid
        
            block_bottom_index = block_bottom_index + 1;
            block_top_index = block_top_index - 1;
            block_left_index = block_left_index + 1;
            block_right_index = block_right_index - 1;
            if block_top_index <= block_bottom_index + 2 || block_right_index <= block_left_index + 2
                % If the block is too small, just return an empty eddy
                eddy = new_eddy();
                return;
            end
        end
        
        block = ssh(block_bottom_index:block_top_index, block_left_index:block_right_index);
        
        extremaBlock = extrema(block_bottom_index:block_top_index, block_left_index:block_right_index);

    else
        edgeOfWorld = false;
        block = ssh(block_bottom_index:block_top_index, block_left_index:block_right_index);
        extremaBlock = extrema(block_bottom_index:block_top_index, block_left_index:block_right_index);
    end
    
    if isnan(last_step)
        step = threshold_step;
    else
        step = last_step;
    end
    
    iter = 1;
    while true
        iter = iter+1;
        if iter > 5000

            perim = imdilate(logical(current), ones(3)) & ~logical(current);
            if all(isnan(block(perim)))
                eddy = new_eddy();
                return;
            end
            disp('potential infinite loop')
        end

        bw = cyc .* block >= cyc .* thresh;
        labels = bwlabel(bw);

        extrema_label = labels(extrema_lat_index - block_bottom_index + 1, extrema_lon_index - block_left_index + 1);
        current = labels == extrema_label;
        currentExtrema = extremaBlock(current);
        
        existing_pixel_at_box_edge = outterRing(labels, extrema_label);

        if sum(currentExtrema) > 1 || ( edgeOfWorld && existing_pixel_at_box_edge)
            
            if step ~= threshold_step
                % Go back to last threshold
                thresh = thresh + cyc*step;
                step = threshold_step;
                thresh = thresh - cyc*step;
                continue;
            end

            if size(block, 1) ~= size(previous(block_bottom_index:block_top_index, block_left_index:block_right_index), 1)
                prevBlock = block(2:end-1, 2:end-1);
            else
                prevBlock = block;
            end

            perim = imdilate(logical(previous(block_bottom_index:block_top_index, block_left_index:block_right_index)), ones(3)) ...
                & ~logical(previous(block_bottom_index:block_top_index, block_left_index:block_right_index));
            nan = isnan(prevBlock(perim));
            if sum(nan) / length(nan) > .3
                %if more than half of your perimeter is land, then throw it out.
                eddy = new_eddy();
                return;
            end

            if sum(previous(:)) < min_pixel_size
                    eddy = new_eddy();
                    return;
            end

            perim = bwperim(previous);
            meanPerim = mean(ssh(logical(perim)));
            amp = cyc * (ssh(extrema_lat_index, extrema_lon_index)-meanPerim);
            
            stats = regionprops(previous, ssh, 'Area', 'Extrema',...
                'PixelIdxList', intensity, 'ConvexImage', 'PixelList', ...
                'Solidity', 'Extent', 'Orientation', 'MajorAxisLength', ...
                'MinorAxisLength');
            
            stats.Intensity = stats.(intensity);
            stats = rmfield(stats, intensity);
            
            if is_padding
                [idx, r, c] = extidx2original(stats.PixelIdxList, [length(lat) length(lon)], size(ssh));
                stats.PixelIdxList = idx; 
            else
                [r, c] = ind2sub(size(ssh), stats.PixelIdxList);
            end
            
            stats.PixelList = [r, c];

            % Getting geodesic speed
            if is_padding
                geoSpeed = mean_geo_speed(ssh(:, 201:end-200), stats.PixelIdxList, lat, lon);
                if ~isempty(R)
                    [elat, elon] = weighted_centroid(cyc_ssh(:, 201:end-200), stats.PixelList, stats.PixelIdxList, R);
                else
                    [elat, elon] = weighted_centroid_irregular_grid(cyc_ssh(:, 201:end-200), stats.PixelList, stats.PixelIdxList, lat, lon);
                end
            else
                geoSpeed = mean_geo_speed(ssh, stats.PixelIdxList, lat, lon);
                if ~isempty(R)
                    [elat, elon] = weighted_centroid(cyc_ssh, stats.PixelList, stats.PixelIdxList, R);
                else
                    [elat, elon] = weighted_centroid_irregular_grid(cyc_ssh, stats.PixelList, stats.PixelIdxList, lat, lon);
                end
            end
            
            % weighted_centroid returns lon from 0-360, fix this
            % TODO: should we also fix lat lon -270 to 80?
            elon = (elon > 180).*(elon - 360) + (elon <= 180).*elon;
            
            % Getting surface area of the eddy
            if all(size(areamap) == [length(lat) length(lon)]) 
                % area is 2D array for areas of pixels at [lat, lon]
                sarea = sum(areamap(stats.PixelIdxList));
            elseif any(size(areamap) == [1 1]) && length(areamap) == length(lat) 
                % Area is 1D array for areas of pixels at a specific latitude
                sarea = sum(areamap(stats.PixelList(:, 1)));
            else
                % Invalid areamap
                sarea = NaN;
            end
            
            eddy = new_eddy(rmfield(stats, 'PixelList'), amp, elat, elon, thresh, sarea, cyc, geoSpeed, 'ESv2');

            return
        end

        if existing_pixel_at_box_edge
            %disp('expanding size');
            eddy = thresholdBU(cyc, block_bottom_index-1, block_top_index+1, block_left_index-1,...
                block_right_index+1, ssh, extrema, extrema_lat_index, extrema_lon_index, thresh, threshold_step, ...
                step, previous, lat, lon, R, areamap, min_pixel_size, ...
                is_padding, cyc_ssh);
            return
        end

        previous(block_bottom_index:block_top_index, block_left_index:block_right_index) = current;
        
        step = step * 2; % double the step for less number of iterations
        thresh = thresh - cyc*step;
    end

end

function [ extrema ] = get_extrema( ssh, cyc )
%GET_EXTREMA Returns a matrix containing all of the minima or maxima
%(depending on the value of cyc) in a 5x5 matrix within the 2D ssh field.
% ssh: ssh slice containing NaNs for land
% cyc: 1 for anticyclonic, -1 for cyclonic

    padded = [ssh(:,end-1:end) ssh(:,:) ssh(:,1:2)];
    padded(isnan(padded)) = cyc*-Inf;
    padded = padarray(padded, [1, 1], cyc*-Inf);
    n = ones(5); n(3, 3) = 0;
    padded = cyc .* padded; % Want to find right extrema for cyclonic and anticyc eddies

    extrema = padded > imdilate(padded, n);
    extrema = extrema(2:end-1, 4:end-3);
end

function [res] = outterRing(box, val)
    ring = [box(1, 1:end)'; box(end, 1:end)'; box(1:end, 1); box(1:end, end)];
    res = any(ring == val);
end

function [idx, row, col] = extidx2original(idx, original_size, extended_size)
%EXTIDX2ORIGINAL Convert from extended indexes to original indexes
    [row, col] = ind2sub(extended_size,idx);
    
    offright = col > (extended_size(2) + original_size(2)) / 2;
    offleft = col < (extended_size(2) - original_size(2)) / 2 + 1;
    notoff = ~(offleft | offright);
    col(offright)=col(offright) - (extended_size(2) + original_size(2)) / 2;
    col(offleft) = col(offleft) + original_size(2) - (extended_size(2) - original_size(2)) / 2;
    col(notoff)=col(notoff) - (extended_size(2) - original_size(2)) / 2;
    
    idx = sub2ind(original_size,row,col);
end

function mean_speed = mean_geo_speed(ssh, pixels, lat, lon)
%MEAN_GEO_SPEED Returns the mean geostrophic speed for pixels.
% lat and lon should yield the correct values for indices of ssh.

    g = 980.665; % cm/s
    omega = 7.2921e-5;
    [x, y] = ind2sub(size(ssh), pixels);
    lats = lat(x);
    f = 2*omega*sin(lats);
    f(f == 0) = 2*omega*sin(0.25); % f is coriolis frequency
    
    dSSH_y = ssh(sub2ind(size(ssh), x, mod(y, size(ssh, 2))+1)) - ...
        ssh(sub2ind(size(ssh), x, mod(y-2, size(ssh, 2))+1));
    dSSH_x = ssh(sub2ind(size(ssh), min(x+1, zeros(size(x)) + size(ssh, 1)), y))...
        - ssh(sub2ind(size(ssh), max(x-1, ones(size(x))), y));

    dy = deg2km(distance(lat(x), lon(mod(y, size(ssh, 1))+1), lat(x), lon(mod(y-2, size(ssh, 1))+1))) * 100000;
    dx = (min(x+1, size(ssh, 1)) - max(1, x-1)) .* 111.12 .* 100000 .* 180 ./ (length(lats) - 1);
    
    vs = -g .* (dSSH_y) ./ (2.*f .* dy);
    us = g .* (dSSH_x) ./ (2 .* f .* dx );
    speeds = sqrt(us .^2 + vs .^2);
    mean_speed = nanmean(speeds);
end

function [lat, lon] = weighted_centroid(cyc_ssh, pixellist, pixelidxlist, R)
%WEIGHTED_CENTROID Returns the location of the weighted centroid for the
%pixels provided
    %ssh = cyc * ssh;
    shift = min(cyc_ssh(pixelidxlist));
    
    x = pixellist(:, 1);
    y = pixellist(:, 2);
    
    if min(y) == 1 && max(y) == size(cyc_ssh,2)
        y(y > size(cyc_ssh,2)/2) = y(y > size(cyc_ssh,2)/2) - size(cyc_ssh,2);
    end
    
    mask = ~isnan(cyc_ssh(pixelidxlist));
    intensities = cyc_ssh(pixelidxlist)+shift;
    intensities = intensities - min(intensities); % should start from 0
    
    xbar = sum(x(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    ybar = sum(y(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    
    if ybar <= 0
        ybar = ybar + size(cyc_ssh,2);
    end
    
    [lat, lon] = pix2latlon(R, xbar, ybar);

end

function [lat, lon] = weighted_centroid_irregular_grid(cyc_ssh, pixellist, pixelidxlist, lats, lons)
%WEIGHTED_CENTROID_IRREGULAR_GRID Returns the location of the weighted centroid for the
%pixels provided
    %ssh = cyc * ssh;
    shift = min(cyc_ssh(pixelidxlist));
    
    x = pixellist(:, 1);
    y = pixellist(:, 2);
    
    if min(y) == 1 && max(y) == size(cyc_ssh,2)
        y(y > size(cyc_ssh,2)/2) = y(y > size(cyc_ssh,2)/2) - size(cyc_ssh,2);
    end
    
    mask = ~isnan(cyc_ssh(pixelidxlist));
    intensities = cyc_ssh(pixelidxlist)+shift;
    intensities = intensities - min(intensities); % should start from 0
    xbar = sum(x(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    ybar = sum(y(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    
    if ybar <= 0
        ybar = ybar + size(cyc_ssh,2);
    end

    x_lower = floor(xbar);
    x_upper = ceil(xbar);
    if x_lower == 0
        lat = lats(1);
    elseif x_upper == length(lats) + 1
        lat = lats(end);
    else
        lat_lower = lats(x_lower);
        lat_upper = lats(x_upper);
        lat = lat_lower + (lat_upper - lat_lower) * (xbar - x_lower) / (x_upper - x_lower);
        if isnan(lat)
            lat = 90;
        end
    end
    y_lower = floor(ybar);
    y_upper = ceil(ybar);
    if y_lower == 0
        lon = lons(1);
    elseif y_upper == length(lons) + 1
        lon = lons(end);
    else
        lon_lower = lons(y_lower);
        lon_upper = lons(y_upper);
        if lon_upper - lon_lower > 180
            lon_upper = lon_upper - 360;
        elseif lon_lower - lon_upper > 180
            lon_lower = lon_lower - 360;
        end
        lon = lon_lower + (lon_upper - lon_lower) * (ybar - y_lower) / (y_upper - y_lower);
    end

end


function eddy = new_eddy(STATS, amplitude, lat, lon, thresh, sa, cyc, geospeed, detect)
%NEW_EDDY Initializes new eddy objects, run with no arguments to create an
%empty matrix
    if nargin
        eddy = struct('Stats', STATS, ...
            'Lat', lat, ...
            'Lon', lon, ...
            'Amplitude', amplitude, ...
            'ThreshFound', thresh, ...
            'SurfaceArea', sa, ...
            'Date', NaN, ...
            'Cyc', cyc, ...
            'MeanGeoSpeed', geospeed, ...
            'DetectedBy', detect);
    else
        eddy = struct('Stats', [], ...
            'Lat', [], ...
            'Lon', [], ...
            'Amplitude', [], ...
            'ThreshFound', [], ...
            'SurfaceArea', [], ...
            'Date', [], ...
            'Cyc', [], ...
            'MeanGeoSpeed', [], ...
            'DetectedBy', []);
    end
end
