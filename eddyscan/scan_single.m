function [ eddies ] = scan_single( ssh, lat, lon, date, cyc, scan_type )
%SCAN_SINGLE Wrapper function to do scanning
% ssh: ssh slice with nans for land
% cyc: 'anticyc' or 'cyclonic'
% scan_type: 'v1', 'v2', 'hybrid'
%         v1: Will run top-down scanning
%         v2: Will run bottom-up scanning from the minima of the field
%     hybrid: Will run v2 and v1 scanning and will take the union of the
%             two sets where, for common features, v2 bodies will be used
    if ~any(isnan(ssh(:)))
        error('Invalid ssh data, must contain NaNs for land values');
    end
    
    stype = get_stype();
    ctype = get_ctype();
    
    ampath = mfilename('fullpath');
    sep = strfind(ampath, filesep());
    ampath = ampath(1:sep(end-1));
    areamap = load([ampath 'data/quadrangle_area_by_lat.mat']);
    areamap = areamap.areamap;
    
    oldpath = addpath('lib');
    
    switch stype
        case 1
            eddies = eddyscan_single(ssh, lat, lon, areamap, ctype);
        case 2
            eddies = bottom_up_single(ssh, lat, lon, areamap, ctype);
        case 0
            scanners = {@eddyscan_single, @bottom_up_single};
            eddies_out = {[], []};
            parfor i = 1:2
                eddies_out{i} = scanners{i}(ssh, lat, lon, ctype);
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

