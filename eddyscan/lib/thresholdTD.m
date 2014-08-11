function [ eddy, newBWMask] = thresholdTD( cyc, ssh_data, ssh_extended,ssh_extended_data, currentThresh,...
    lat, lon, R, areamap, minimumArea, maximumArea, convexRatioLimit, minAmplitude, minExtrema, bwMask, areas, lmat, index)
% return a single eddy at one sepcific thresholding value and under one
% of CC object
% 'currentThresh' : current thresholding value used to scan this eddy
% all the other parameters are the same in top_down_single.m
if cyc==1
    intensity = 'MaxIntensity';
elseif cyc==-1
    intensity = 'MinIntensity';
end

%return empty if not eddy
eddy = [];

newBWMask = bwMask;
%%

blobbw = (lmat==index);

STATS = regionprops(blobbw, ssh_extended_data, 'Area', 'Extrema',...
    'PixelIdxList', intensity, 'ConvexImage', 'BoundingBox', ...
    'Centroid', 'Solidity', 'Extent', 'Orientation', ...
    'MajorAxisLength', 'MinorAxisLength');

STATS.Intensity = STATS.(intensity);
STATS = rmfield(STATS, intensity);

extPixelIdxList = STATS.PixelIdxList;
[STATS.PixelIdxList, r, c] = extidx2original(STATS.PixelIdxList, size(ssh_data), size(ssh_extended));
STATS.PixelList = [r, c];
if ( (minimumArea <= STATS.Area) && (STATS.Area <= maximumArea) )
    blobpmtr = bwperim(blobbw);
    meanpmtr = mean(ssh_extended_data(blobpmtr == 1));
    amplitude = cyc*(STATS.Intensity - meanpmtr);
    
    if ( (amplitude >= minAmplitude)  && (getNumberOfLocalExtrema(STATS.PixelIdxList) >= minExtrema) )
        if ~isempty(R)
        	[centroid_lat, centroid_lon] = get_centroid(r,c);
        else
        	[centroid_lat, centroid_lon] = weighted_centroid_irregular_grid(ssh_data, STATS.PixelList, STATS.PixelIdxList, cyc, lat, lon);
        end
        surface_area = get_image_area(r);
        convex_pass = false;  %#ok<NASGU>
        bb = STATS.BoundingBox;
        convex_image = zeros(size(blobbw));
        i_start = ceil(bb(2));
        i_end = i_start+bb(4)-1;
        j_start = ceil(bb(1));
        j_end = j_start+bb(3)-1;
        convex_image(i_start:i_end,j_start:j_end) = STATS.ConvexImage(:,:);
        [dummy, convr, ~] = extidx2original(find(convex_image), size(ssh_data), size(ssh_extended)); %#ok<ASGLU>
        convex_area = get_image_area(convr);
        
        
        maxdist = get_max_dist(STATS.Extrema);
        maxdist_lim = get_maxdist_limit(centroid_lat);
        
        if maxdist >= maxdist_lim
            return
        end
        
        if test_convexity(centroid_lat, convex_area)
            convexity_ratio = surface_area/convex_area;  
            convex_pass = convexity_ratio > convexRatioLimit;
        else
            convex_pass = true;
        end
        
        if ~convex_pass
            return
        end
        
        if STATS.Centroid(1) <= 1640 && STATS.Centroid(1) > 200
            %display(['    ' num2str(idx) ' eddies found.']);
            geospeed = mean_geo_speed(ssh_data, ...
                STATS.PixelIdxList, lat, lon);
            eddy = new_eddy(...
                rmfield(STATS, {'Centroid' 'BoundingBox'}), ...
                amplitude, centroid_lat, centroid_lon, ...
                currentThresh, surface_area, cyc, geospeed,'ESv1');
        else
            %display('duplicate eddy found');
        end
        bwMask(extPixelIdxList) = 0;
        newBWMask = bwMask;
    end
end

%% Helper Functions
    function [bool] = test_convexity(lat, surface_area)
        bool = surface_area>areas(round(abs(lat))+1);
    end

    function [maxdist] = get_max_dist(extrema)
        pixels = zeros(size(extrema));
        pixels(1:4,1) = floor(extrema(1:4,1));
        pixels(5:8,1) = ceil(extrema(5:8,1));
        pixels([1 2 7 8],2) = floor(extrema([1 2 7 8],2));
        pixels(3:6,2) = ceil(extrema(3:6,2));
        ivals = pixels(:,1);
        offright = ivals > 1640;
        offleft = ivals < 201;
        notoff = ~(offright | offleft);
        ivals(offright) = ivals(offright) - 1640;
        ivals(offleft) = ivals(offleft) + 1240;
        ivals(notoff) = ivals(notoff) - 200;
        pixels(:,1) = ivals;
        combos = nchoosek(1:8,2);
        latlons = zeros(size(combos,1),2*size(combos,2));
        for row = 1:size(combos, 1)
            x1 = mod(pixels(combos(row,1),1), length(lon)) + 1;
            y1 = pixels(combos(row,1),2);
            x2 = mod(pixels(combos(row,2),1), length(lon)) + 1;
            y2 = pixels(combos(row,2),2);
            if y2 > length(lat)
                y2 = length(lat);
            end
            if y1 > length(lat)
                y1 = length(lat);
            end
            latlons(row,:) = [lat(y1) lon(x1) lat(y2) lon(x2)];
        end
        dists = zeros(1,28);
        for x=1:size(dists,2)
            dists(x) = deg2km(distance(latlons(x,1), latlons(x,2), ...
                latlons(x,3), latlons(x,4)));
        end
        maxdist = max(dists);
    end

    function [max_dist_limit] = get_maxdist_limit(lat)
        if abs(lat)>=25
            max_dist_limit = 400;
        else
            max_dist_limit = 1200-32*abs(lat);
        end
    end

    function [area] = get_image_area(rows)
        area = sum(areamap(rows));
    end

    function [lat, lon] = get_centroid(i,j)
        % Returns lat and lon of eddy centroid.
        %[i j] = ind2sub(size(ssh_data), pxidxs);
        [lat, lon] = pix2latlon(R,i,j);
        [lat, lon] = meanm(lat, lon);
        lon = (lon > 180).*(lon - 360) + (lon <= 180).*lon;
    end

    function [counter] = getNumberOfLocalExtrema( pxidxs )
        [px_i, px_j] = ind2sub(size(ssh_data), pxidxs);
        counter = 0;
        for ii = 1:length(pxidxs)
            corei = px_i(ii)-1:px_i(ii)+1;
            if corei(3) > size(ssh_data, 1)
                corei = px_i(ii)-2:px_i(ii);
            end
            corej = mod(px_j(ii)-2:px_j(ii), size(ssh_data, 2))+1;
            if sum(sum(cyc.*ssh_data(pxidxs(ii)) > cyc.*ssh_data(corei, corej))) == 8
                counter = counter + 1;
            end
        end
    end
end

