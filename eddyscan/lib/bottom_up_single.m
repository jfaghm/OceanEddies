function [ eddies ] = bottom_up_single(ssh_data, lat, lon, areamap, cyc, is_padding)
%BOTTOM_UP_SINGLE Finds eddies using the Bottom Up method
%   Will return an array of struct's that contain the eddy data.
%   ssh_data: A 2D array of double's that contain the sea surface heights (latsxlons)
%   lats: A 1D array of double's that gives the latitude for a given index (dimension should match
%         that of ssh_data)
%   lons: A 1D array of double's that gives the longitude for a given index (dimension should match
%         that of ssh_data)
%   cyc: Pass 1 to output anticyclonic eddies or -1 to output cyclonic eddies

    min_pixel_size = 9;
    
    geo_raster_lat_limit = [lat(1) lat(end)];
    if lon(1) > lon(end)
        geo_raster_lon_limit = [lon(1) (360 + lon(end))];
    else
        geo_raster_lon_limit = [lon(1) lon(end)];
    end
    
    R = georasterref('LatLim', geo_raster_lat_limit, 'LonLim', geo_raster_lon_limit, 'RasterSize', ...
    size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');
    
    extrema = get_extrema(ssh_data, cyc);
    
    if is_padding
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
%     parfor i = 1:length(extrema_lat_indexes)
    for i = 1:length(extrema_lat_indexes)
        curr_lat_index = extrema_lat_indexes(i); curr_lon_index = extrema_lon_indexes(i);
        e = thresholdBU(cyc, curr_lat_index-5, curr_lat_index+5, curr_lon_index-5, curr_lon_index+5, ...
            sshExtended, extrema, curr_lat_index, curr_lon_index, sshExtended(curr_lat_index, curr_lon_index), ...
            zeros(size(sshExtended)), lat, lon, R, areamap, min_pixel_size, is_padding);
        if ~isempty(e)
            eddies(i) = e;
        end
    end
    mask = cellfun('isempty', {eddies.Lat});
    eddies = eddies(~mask);
end

function [eddy] = thresholdBU(cyc, block_bottom_index, block_top_index, block_left_index, ...
        block_right_index, ssh, extrema, x, y, thresh, previous, lat, lon, R, areamap, min_pixel_size, is_padding)
    
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
        
        block_bottom_index = max([block_bottom_index 1]); 
        block_top_index = min([block_top_index size(ssh, 1)]); 
        block_left_index = max([block_left_index 1]); 
        block_right_index = min([block_right_index size(ssh, 2)]);
        
        block = ssh(block_bottom_index:block_top_index, block_left_index:block_right_index);
        
        extremaBlock = extrema(block_bottom_index:block_top_index, block_left_index:block_right_index);

    else
        edgeOfWorld = false;
        block = ssh(block_bottom_index:block_top_index, block_left_index:block_right_index);
        extremaBlock = extrema(block_bottom_index:block_top_index, block_left_index:block_right_index);
    end
    
    step = .05;
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

        current = labels == labels(x - block_bottom_index + 1, y - block_left_index + 1);
        currentExtrema = extremaBlock(current);

        if sum(currentExtrema) > 1 || edgeOfWorld            

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

            %plotBox(previous, ssh);


            perim = bwperim(previous);
            meanPerim = mean(ssh(logical(perim)));
            amp = cyc * (ssh(x, y)-meanPerim);
            
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
            
            if is_padding
                geoSpeed = mean_geo_speed(ssh(:, 201:end-200), stats.PixelIdxList, lat, lon);
                [elat, elon] = weighted_centroid(ssh(:, 201:end-200), stats.PixelList, stats.PixelIdxList, cyc, R);
            else
                geoSpeed = mean_geo_speed(ssh, stats.PixelIdxList, lat, lon);
                [elat, elon] = weighted_centroid(ssh, stats.PixelList, stats.PixelIdxList, cyc, R);
            end
            
            % weighted_centroid returns lon from 0-360, fix this
            elon = (elon > 180).*(elon - 360) + (elon <= 180).*elon;
            sarea = get_image_area(stats.PixelList(:,1));
            eddy = new_eddy(rmfield(stats, 'PixelList'), amp, elat, elon, thresh, sarea, cyc, geoSpeed, 'ESv2');

            return
        end

        if outterRing(labels, labels(x - block_bottom_index+1, y - block_left_index + 1))
            %disp('expanding size');
            eddy = thresholdBU(cyc, block_bottom_index-1, block_top_index+1, block_left_index-1,...
                block_right_index+1, ssh, extrema, x, y, thresh, previous, lat, lon, R, areamap, min_pixel_size, ...
                is_padding);
            return
        end

        previous(block_bottom_index:block_top_index, block_left_index:block_right_index) = current;
        thresh = thresh - cyc*step;
    end

    function area = get_image_area(rows)
        area = sum(areamap(rows));
    end
end

function [res] = outterRing(box, val)
    ring = [box(1, 1:end)'; box(end, 1:end)'; box(1:end, 1); box(1:end, end)];
    res = any(ring == val);
end