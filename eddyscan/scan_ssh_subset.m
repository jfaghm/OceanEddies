function scan_ssh_subset( ssh, lat, lon, dates, cyc, scan_type, destdir )
%SCAN_SSH_SUBSET Scan all of the ssh data passed in (will function
%correctly if data passed in is a subset)
    if ~strcmp(destdir(end), filesep())
        destdir = [destdir filesep()];
    end
    if exist(destdir, 'dir') ~= 7
        mkdir(destdir);
    end
    parfor i = 1:length(dates)
        fprintf('starting iteration %d\n', i);
        eddies = scan_single(ssh(:,:,i), lat, lon, dates(i), cyc, scan_type);
        save_data([destdir cyc '_' num2str(dates(i))], eddies);
        fprintf('finished iteration %d\n', i);
    end
end

function save_data(path, eddies)
    save(path, 'eddies', '-v7');
end