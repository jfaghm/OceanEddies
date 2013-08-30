function scan_multi( ssh, lat, lon, dates, cyc, scan_type, destdir )
%SCAN_MULTI Scan all of the ssh data passed in (will function correctly if data
%passed in is a subset)
% ssh: ssh cube with nans for land
% cyc: 'anticyc' or 'cyclonic'
% scan_type: 'v1', 'v2', 'hybrid'
%         v1: Will run top-down scanning
%         v2: Will run bottom-up scanning from the minima of the field
%     hybrid: Will run v2 and v1 scanning and will take the union of the
%             two sets where, for common features, v2 bodies will be used
    if ~strcmp(destdir(end), filesep())
        destdir = [destdir filesep()];
    end
    if exist(destdir, 'dir') ~= 7
        mkdir(destdir);
    end
    parfor i = 1:length(dates)
        if exist([destdir cyc '_' num2str(dates(i)) '.mat'], 'file')
            continue;
        end
        fprintf('starting iteration %d\n', i);
        eddies = scan_single(ssh(:,:,i), lat, lon, dates(i), cyc, scan_type);
        save_data([destdir cyc '_' num2str(dates(i))], eddies);
        fprintf('finished iteration %d\n', i);
    end
end

function save_data(path, eddies)
    save(path, 'eddies', '-v7');
end
