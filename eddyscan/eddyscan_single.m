function [ eddies ] = eddyscan_single(ssh_data, lats, lons, cyc)
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

areamap = load('../data/quadrangle_area_by_lat.mat');
areamap = areamap.areamap;

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
R = georasterref('LatLim', [-90 90], 'LonLim', [0 360], 'RasterSize', size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');

if cyc==1
    thresh_range = 0:.005:1;
    intensity = 'MaxIntensity';
%     cycid = 'Anticyclonic';
elseif cyc==-1
    thresh_range = 1:-.005:0;
    intensity = 'MinIntensity';
%     cycid = 'Cyclonic';
end

idx = 1;
eddies = new_eddy();
%display(['============== Finding ' cycid ' Eddies for Date: ' num2str(date) ' ==============']);

%% Main Algorithm
for thresh=thresh_range
    realthresh = thresh*200-100;
%     display(['Threshold value is currently ' num2str(realthresh)]);
    bw = im2bw(ssh_extended, thresh);
    if cyc==-1
        bw = imcomplement(bw);
    end
    bw = bw.*mask;
    CC = bwconncomp(bw);
    lmat = labelmatrix(CC);
    %display(['  ' num2str(CC.NumObjects) ' objects found.']);
    
    for n=1:CC.NumObjects
        blobbw = (lmat==n);
        
        STATS = regionprops(blobbw, ssh_extended_data, 'Area', 'Extrema',...
            'PixelIdxList', intensity, 'ConvexImage', 'BoundingBox', ...
            'Centroid', 'PixelList', 'Solidity', 'Extent', 'Orientation', ...
            'MajorAxisLength', 'MinorAxisLength');
        extPixelIdxList = STATS.PixelIdxList;
        [STATS.PixelIdxList, r, c] = extidx2original(STATS.PixelIdxList);
        if ( (8<STATS.Area) && (STATS.Area<1000) )
            blobpmtr = bwperim(blobbw);
            meanpmtr = mean(ssh_extended_data(blobpmtr == 1));
            
            if cyc==1
                amplitude = STATS.MaxIntensity - meanpmtr;
            elseif cyc==-1
                amplitude = meanpmtr - STATS.MinIntensity;
            end
            
            if ( (amplitude>=1)  && (has_local_maxmin(STATS.PixelIdxList)) )
                [centroid_lat, centroid_lon] = get_centroid(r,c);
                surface_area = get_image_area(r);
                convex_pass = false; %#ok<NASGU>
                bb = STATS.BoundingBox;
                convex_image = zeros(size(blobbw));
                i_start = ceil(bb(2));
                i_end = i_start+bb(4)-1;
                j_start = ceil(bb(1));
                j_end = j_start+bb(3)-1;
                convex_image(i_start:i_end,j_start:j_end) = STATS.ConvexImage(:,:);
                [dummy, convr, ~] = extidx2original(find(convex_image)); %#ok<ASGLU>
                convex_area = get_image_area(convr);
                
                
                maxdist = get_max_dist(STATS.Extrema);
                maxdist_lim = get_maxdist_limit(centroid_lat);
                
                if maxdist >= maxdist_lim
                    continue;
                end
                
                if test_convexity(centroid_lat, convex_area)
                    test = test+1;
                    convex_pass = surface_area/convex_area>convexity_ratio_limit;
                else
                    no_test = no_test+1;
                    convex_pass = true;
                end
                
                if ~convex_pass
                    continue;
                end
                
                if STATS.Centroid(1) <= 1640 && STATS.Centroid(1) > 200
                    %display(['    ' num2str(idx) ' eddies found.']);
                    geospeed = mean_geo_speed(ssh_data, ...
                        STATS.PixelIdxList, lats, lons);
                    eddies(idx) = new_eddy(STATS,...
                        amplitude, centroid_lat, centroid_lon,...
                        realthresh, surface_area, cyc, geospeed);
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
        if cyc==1
            % For anticyclic we need to find local max
            pixcount = 1;
            while (~bool) && (pixcount<=length(pxidxs))
                % Iterate through pixels, if max is found return true.
                delta_i = -1;
                delta_j = -1;
                [i, j] = ind2sub(size(ssh_data), pxidxs(pixcount));
                bool = true;
                while bool && (delta_i<=1)
                    while bool && (delta_j<=1)
                        if delta_i||delta_j % Avoid comparing pixel to itself.
                            compi = mod(i + delta_i, size(ssh_data,1));
                            if ~compi
                                compi = size(ssh_data, 1);
                            end
                            compj = mod(j + delta_j, size(ssh_data,2));
                            if ~compj
                                compj = size(ssh_data, 2);
                            end
                            bool = ssh_data(i,j)>ssh_data(compi,compj);
                        end
                        delta_j=delta_j+1;
                    end
                    delta_i=delta_i+1;
                end
                pixcount = pixcount+1;
            end
        elseif cyc==-1
            % Local min.
            pixcount = 1;
            while (~bool) && (pixcount<=length(pxidxs))
                % Iterate through pixels, if max is found return true.
                delta_i = -1;
                delta_j = -1;
                [i, j] = ind2sub(size(ssh_data), pxidxs(pixcount));
                bool = true;
                while bool && (delta_i<=1)
                    while bool && (delta_j<=1)
                        if delta_i||delta_j % Avoid comparing pixel to itself.
                            compi = mod(i + delta_i, size(ssh_data,1));
                            if ~compi
                                compi = size(ssh_data, 1);
                            end
                            compj = mod(j + delta_j, size(ssh_data,2));
                            if ~compj
                                compj = size(ssh_data, 2);
                            end
                            bool = ssh_data(i,j)<ssh_data(compi,compj);
                        end
                        delta_j=delta_j+1;
                    end
                    delta_i=delta_i+1;
                end
                pixcount = pixcount+1;
            end
        end
    end

    function [idx, row, col] = extidx2original(idx)
        [row, col] = ind2sub(size(ssh_extended),idx);
        offright = col > 1640;
        offleft = col < 201;
        notoff = ~(offleft | offright);
        col(offright)=col(offright)-1640;
        col(offleft)=col(offleft)+1240;
        col(notoff)=col(notoff)-200;
        idx = sub2ind(size(ssh_data),row,col);
    end

    function eddy = new_eddy(STATS, amplitude, lat, lon, thresh, sa, cyc, geospeed)
        if nargin
            eddy = struct('Stats', STATS, ...
                'Lat', lat, ...
                'Lon', lon, ...
                'Amplitude', amplitude, ...
                'ThreshFound', thresh, ...
                'SurfaceArea', sa, ...
                'Date', NaN, ...
                'Cyc', cyc, ...
                'MeanGeoSpeed', geospeed);
        else
            eddy = struct('Stats', {}, ...
                'Lat', {}, ...
                'Lon', {}, ...
                'Amplitude', {}, ...
                'ThreshFound', {}, ...
                'SurfaceArea', {}, ...
                'Date', {}, ...
                'Cyc', {}, ...
                'MeanGeoSpeed', {});
        end
    end
end
    



