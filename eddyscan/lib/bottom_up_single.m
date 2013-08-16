function [ eddies ] = bottom_up_single(ssh_data, lat, lon, areamap, cyc)
%BOTTOM_UP_SINGLE Finds eddies using the Bottom Up method
%   Will return an array of struct's that contain the eddy data.
%   ssh_data: A 2D array of double's that contain the sea surface heights (latsxlons)
%   lats: A 1D array of double's that gives the latitude for a given index (dimension should match
%         that of ssh_data)
%   lons: A 1D array of double's that gives the longitude for a given index (dimension should match
%         that of ssh_data)
%   cyc: Pass 1 to output anticyclonic eddies or -1 to output cyclonic eddies

    R = georasterref('LatLim', [-90 90], 'LonLim', [0 360], 'RasterSize', ...
    [721, 1440], 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');
    
    extrema = get_extrema(ssh_data, cyc);
    origExtrema = extrema;
    extrema = [zeros(size(extrema, 1), 200), extrema, zeros(size(extrema, 1), 200)];

    sshExtended = [ssh_data(:, end-199:end), ssh_data(:, :), ssh_data(:, 1:200)];

    [x, y] = ind2sub(size(extrema), find(extrema == 1));

    extrema(:, 1:200) = origExtrema(:, end-199:end);
    extrema(:, end-199:end) = origExtrema(:, 1:200);

    eddies = new_eddy();
    eddies(length(x)).Date = NaN;
    parfor j = 1:length(x)
        xx = x(j); yy = y(j);
        [~,~,e] = thresholdBU(cyc, xx-5, xx+5, yy-5, yy+5, sshExtended, extrema, ...
            xx, yy, sshExtended(xx, yy), zeros(size(sshExtended)), lat, lon, R, areamap);
        if ~isempty(e)
            eddies(j) = e;
        end
    end
    mask = cellfun('isempty', {eddies.Lat});
    eddies = eddies(~mask);
end

function [pixelX, pixelY, eddy] = thresholdBU(cyc, left, right, top, bottom, ...
        ssh, extrema, x, y, thresh, previous, lat, lon, R, areamap)
    switch cyc
        case 1
            intensity = 'MaxIntensity';
        case -1
            intensity = 'MinIntensity';
        otherwise
            error('Invalid cyc');
    end

    try
        block = ssh(left:right, top:bottom);
        extremaBlock = extrema(left:right, top:bottom);
        edgeOfWorld = false;
    catch
        left = left+1; right = right-1; top = top+1; bottom = bottom-1;
        block = ssh(left:right, top:bottom);
        extremaBlock = extrema(left:right, top:bottom);
        edgeOfWorld = true;
    end
    step = .05;
    iter = 1;
    while true
        iter = iter+1;
        if iter > 5000

            perim = imdilate(logical(current), ones(3)) & ~logical(current);
            if all(isnan(block(perim)))
                pixelX = []; pixelY = []; eddy = new_eddy();
                return;
            end
            disp('potential infinite loop')
        end

        bw = cyc .* block >= cyc .* thresh;
        labels = bwlabel(bw);

        current = labels == labels(x - left + 1, y - top + 1);
        currentExtrema = extremaBlock(current);

        if sum(currentExtrema) > 1 || edgeOfWorld            
            %if more than half of your perimeter is land, then throw it out.
            if size(block, 1) ~= size(previous(left:right, top:bottom), 1)
                prevBlock = block(2:end-1, 2:end-1);
            else
                prevBlock = block;
            end

            perim = imdilate(logical(previous(left:right, top:bottom)), ones(3)) ...
                & ~logical(previous(left:right, top:bottom));
            nan = isnan(prevBlock(perim));
            if sum(nan) / length(nan) > .3
                pixelX = []; pixelY = []; eddy = new_eddy();
                return;
            end

            if sum(previous(:)) < 9
                    pixelX = []; pixelY = []; eddy = new_eddy();
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
            
            [idx, r, c] = extidx2original(stats.PixelIdxList);
            stats.PixelIdxList = idx; stats.PixelList = [r, c];
            geoSpeed = mean_geo_speed(ssh(:, 201:end-200), stats.PixelIdxList, lat, lon);
            [elat, elon] = weighted_centroid(ssh(:, 201:end-200), stats.PixelList, stats.PixelIdxList, cyc, R);
            % weighted_centroid returns lon from 0-360, fix this
            elon = (elon > 180).*(elon - 360) + (elon <= 180).*elon;
            sarea = get_image_area(stats.PixelList(:,1));
            eddy = new_eddy(rmfield(stats, 'PixelList'), amp, elat, elon, thresh, sarea, cyc, geoSpeed, 'ESv2');

            [pixelX, pixelY] = ind2sub(size(ssh), find(previous == 1));
            return
        end



        if outterRing(labels, labels(x - left+1, y - top + 1))
            %disp('expanding size');
            [pixelX, pixelY, eddy] = thresholdBU(cyc, left-1, right+1, top-1,...
                bottom+1, ssh, extrema, x, y, thresh, previous, lat, lon, R, areamap);
            return
        end

        previous(left:right, top:bottom) = current;
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