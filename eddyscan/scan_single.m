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
%   'minimumArea': minimum number of pixels for an eddy, used for validating eddies
%   'thresholdStep': the minimum step for thresholding, the unit is SSH's unit
%   'isPadding': whether or not to pad SSH data, should be true when scanning SSH data with the longitudes expanding the 
%   whole world dmap. Set to false if only partial SSH data is used.

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
    
    stype = get_stype();
    ctype = get_ctype();
    
    oldpath = addpath('lib');
    
    switch stype
        case 1
            eddies = eddyscan_single(ssh, lat, lon, areamap, ctype);
        case 2
            eddies = bottom_up_single(ssh, lat, lon, areamap, ctype, varargin{:});
        case 0
            scanners = {@eddyscan_single, @bottom_up_single};
            eddies_out = {[], []};
            parfor i = 1:2
                eddies_out{i} = scanners{i}(ssh, lat, lon, areamap, ctype, varargin{:});
            end
            eddies = get_combined_eddy_frames(eddies_out{2}, eddies_out{1}, ssh);
    end
    [eddies.Date] = deal(date);
    
    path(oldpath);

    function scan_t = get_stype()
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

    function cyc_t = get_ctype()
        switch cyc
            case 'anticyc'
                cyc_t = 1;
            case 'cyclonic'
                cyc_t = -1;
            otherwise
                error('cyc must be anticyc or cyclonic');
        end
    end
end

