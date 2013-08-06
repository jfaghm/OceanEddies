function [ eddies ] = scan_single( ssh, lat, lon, cyc, scan_type )
%SCAN_SINGLE Wrapper function to do scanning
% ssh: ssh slice with nans for land
% cyc: 'anticyc' or 'cyclonic'
% scan_type: 'v1', 'v2', 'hybrid'
%         v1: Will run top-down scanning
%         v2: Will run bottom-up scanning from the minima of the field
%     hybrid: Will run v2 scanning then run v1 scanning with all of the
%             bodies found by v2 removed (ie. set above the max threshold)
%             and return the combined set of features.
    if ~any(isnan(ssh(:)))
        error('Invalid ssh data, must contain NaNs for land values');
    end
    
    stype = get_stype();
    ctype = get_ctype();
    
    oldpath = addpath('lib');
    
    switch stype
        case 1
            eddies = eddyscan_single(ssh, lat, lon, ctype);
        case 2
            eddies = bottom_up_single(ssh, lat, lon, ctype);
        case 0
            error('Not yet implemented');
    end
    
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

