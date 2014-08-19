function [ eddies ] = eddyscan_single(ssh_data, lats, lons, areamap, cyc)
%EDDYSCAN_SINGLE Finds eddies using Chelton thresholding and
%maxima and convex criteria.
%   Will return an array of struct's that contain the eddy data.
%   ssh_data: A 2D array of double's that contain the sea surface heights (latsxlons)
%   lats: A 1D array of double's that gives the latitude for a given index (dimension should match
%         that of ssh_data)
%   lons: A 1D array of double's that gives the longitude for a given index (dimension should match
%         that of ssh_data)
%   cyc: Pass 1 to output anticyclonic eddies or -1 to output cyclonic eddies

    ssh_extended = zeros(size(ssh_data,1),400+size(ssh_data,2));
    ssh_extended(:,1:200) = ssh_data(:,(end-199):end);
    ssh_extended(:,201:(size(ssh_data,2)+200)) = ssh_data;
    ssh_extended(:,(201+size(ssh_data,2)):end) = ssh_data(:,1:200);

    sshnan = sum(isnan(ssh_data(:))) > 0;
    if sshnan
        mask = ~isnan(ssh_extended);
    else
        landval = max(ssh_data(:));
        mask = ~(ssh_extended == landval);
    end
    ssh_extended_data = ssh_extended;
    ssh_extended = mat2gray(ssh_extended,[-100 100]);

    areas = zeros(1,91);
    areas(1:10) = 200;
    areas(11:81) = 200:-2.6:18;
    areas(82:91) = 18;
    areas = pi()*areas.^2;

    % Comparison parameters. STANDARD IS .85 for ratio limit!!
    convexity_ratio_limit = 0.85;

    % Testing vars.
    test = 0;
    no_test = 0;

    % Create map raster object.
    lat_diffs = lats(2:end) - lats(1:end-1);
    lat_diffs2 = lat_diffs(2:end) - lat_diffs(1:end-1);
    lon_diffs = lons(2:end) - lons(1:end-1);
    lon_diffs(lon_diffs <= -180) = lon_diffs(lon_diffs <= -180) + 360;
    lon_diffs(lon_diffs >= 180) = lon_diffs(lon_diffs >= 180) - 360;
    lon_diffs = abs(lon_diffs);
    lon_diffs2 = lon_diffs(2:end) - lon_diffs(1:end-1);
    if all(lat_diffs2 == 0) && all(lon_diffs2 == 0)
        % Regular grid, create a georasterref object to get eddy's centroid
        geo_raster_lat_limit = [lats(1) lats(end)];
        if lons(1) > lons(end)
            geo_raster_lon_limit = [lons(1) (360 + lons(end))];
        else
            geo_raster_lon_limit = [lons(1) lons(end)];
        end

        R = georasterref('LatLim', geo_raster_lat_limit, 'LonLim', geo_raster_lon_limit, 'RasterSize', ...
         size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');
    else
        % Use normal indexing to get eddy's centroid
        R = [];
    end
    %R = georasterref('LatLim', [-90 90], 'LonLim', [0 360], 'RasterSize', size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');

    if cyc==1
        thresh_range = .49:.00005:.51;
        intensity = 'MaxIntensity';
    %     cycid = 'Anticyclonic';
    elseif cyc==-1
        thresh_range = .51:-.00005:.49;
        intensity = 'MinIntensity';
    %     cycid = 'Cyclonic';
    end

    idx = 1;
    eddies = mod_new_eddy();
    %display(['============== Finding ' cycid ' Eddies for Date: ' num2str(date) ' ==============']);
    %% Main Algorithm
    for thresh=thresh_range
        realthresh = thresh*200-100;
%         display(['Threshold value is currently ' num2str(realthresh)]);
        bw = im2bw(ssh_extended, thresh);
        if cyc==-1
            bw = imcomplement(bw);
        end
        bw = bw.*mask;
        CC = bwconncomp(bw);
        lmat = labelmatrix(CC);
        %display(['  ' num2str(CC.NumObjects) ' objects found.']);
        %disp(['CC.NumObjects found is ', num2str(CC.NumObjects), ' at thresh = ', num2str(thresh)]);
        disp(['Number of CC objects detected: ', num2str(CC.NumObjects)]);
        disp(['Real thresh is: ', num2str(realthresh)]);
        for n=1:CC.NumObjects
            blobbw = (lmat==n);

            STATS = regionprops(blobbw, ssh_extended_data, 'Area', 'Extrema',...
                'PixelIdxList', intensity, 'ConvexImage', 'PixelList', 'BoundingBox', ...
                'Centroid', 'Solidity', 'Extent', 'Orientation', ...
                'MajorAxisLength', 'MinorAxisLength');
            
            STATS.Intensity = STATS.(intensity);
            STATS = rmfield(STATS, intensity);
            
            extPixelIdxList = STATS.PixelIdxList;
            [STATS.PixelIdxList, r, c] = extidx2original(STATS.PixelIdxList, size(ssh_data), size(ssh_extended));
            STATS.PixelList = [r, c];
            %disp(['STATS.Area is ', num2str(STATS.Area)]);
            if ( (8<=STATS.Area) && (STATS.Area<1000) )
                %disp(['STATS.Area is ', num2str(STATS.Area)]);
                blobpmtr = bwperim(blobbw);
                meanpmtr = mean(ssh_extended_data(blobpmtr == 1));
                amplitude = cyc*(STATS.Intensity - meanpmtr);
                %disp(['amplitude is ', num2str(amplitude)]);
                %disp(['local maxmin is ', num2str(has_local_maxmin(STATS.PixelIdxList))]);
                if amplitude >= .01 && has_local_maxmin(STATS.PixelIdxList) > 0
                    %disp(['amplitude is ', num2str(amplitude)]);
                    %disp(['local maxmin is ', num2str(has_local_maxmin(STATS.PixelIdxList))]);
                    if ~isempty(R)
                        [centroid_lat, centroid_lon] = get_centroid(r,c);
                        %[elat, elon] = weighted_centroid(ssh, stats.PixelList, stats.PixelIdxList, cyc, R);
                    else
                        [centroid_lat, centroid_lon] = weighted_centroid_irregular_grid(ssh_data, STATS.PixelList, STATS.PixelIdxList, cyc, lats, lons);
                    end
                    surface_area = get_image_area(r);
                    convex_pass = false; %#ok<NASGU>
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
                        continue;
                    end

%                     if test_convexity(centroid_lat, convex_area)
%                         test = test+1;
%                         convex_pass = surface_area/convex_area>convexity_ratio_limit;
%                     else
%                         no_test = no_test+1;
%                         convex_pass = true;
%                     end
% 
%                     if ~convex_pass
%                         continue;
%                     end
                    %disp(['STATS.Centroid is ', num2str(STATS.Centroid)]);
                    if STATS.Centroid(1) <= 1640 && STATS.Centroid(1) > 200
                        %disp(['Eddy found with STATS.Centroid = ', num2str(STATS.Centroid)]);
                        %display(['    ' num2str(idx) ' eddies found.']);
                        geospeed = mean_geo_speed(ssh_data, ...
                            STATS.PixelIdxList, lats, lons);
                        eddies(idx) = mod_new_eddy(...
                            rmfield(STATS, {'Centroid' 'BoundingBox'}), ...
                            amplitude, centroid_lat, centroid_lon, ...
                            realthresh, surface_area, cyc, geospeed, ...
                            has_local_maxmin(STATS.PixelIdxList), 'ESv1');
                        idx = idx + 1;
                    else
                        %display('duplicate eddy found');
                    end
                    mask(extPixelIdxList) = 0;

                end
            end
        end

        %display(['Test/no_test ratio currently ' num2str(test/no_test) '.']);
    
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
        combos = combntns(1:8,2);
        latlons = zeros(size(combos,1),2*size(combos,2));
        for row = 1:size(combos, 1)
            x1 = mod(pixels(combos(row,1),1), length(lons)) + 1;
            y1 = pixels(combos(row,1),2);
            x2 = mod(pixels(combos(row,2),1), length(lons)) + 1;
            y2 = pixels(combos(row,2),2);
            if y2 > length(lats)
                y2 = length(lats);
            end
            if y1 > length(lats)
                y1 = length(lats);
            end
            latlons(row,:) = [lats(y1) lons(x1) lats(y2) lons(x2)];
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
    
    function [bool] = has_local_maxmin( pxidxs )
        bool = false;
        [px_i, px_j] = ind2sub(size(ssh_data), pxidxs);
        for ii = 1:length(pxidxs)
            corei = px_i(ii)-1:px_i(ii)+1;
            if corei(3) > size(ssh_data, 1)
                corei = px_i(ii)-2:px_i(ii);
            end
            corej = mod(px_j(ii)-2:px_j(ii), size(ssh_data, 2))+1;
            if sum(sum(cyc.*ssh_data(pxidxs(ii)) > cyc.*ssh_data(corei, corej))) == 8
                bool = bool + 1;
                %bool = true;
                %return;
            end
        end
    end
end
    



