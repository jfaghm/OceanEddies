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

function [res] = outterRing(box, val)
    ring = [box(1, 1:end)'; box(end, 1:end)'; box(1:end, 1); box(1:end, end)];
    res = any(ring == val);
end