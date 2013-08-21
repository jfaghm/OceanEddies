function subset_data(ssh, lat, lon, dates, latmin, latmax, lonmin, lonmax, dest)
%SUBSET_DATA This will subset the data and save all of the data into dest
%(as one file, not multiple small files like the global data)
    fprintf('  GEN  %s\n', dest);
    % Correct bounds
    t = load('global/contours');
    contour_mask = t.contour_mask;
    t = load('global/tracks');
    tracks_cell = t.tracks_cell;
    tracks_names = t.tracks_names;
    [~, i] = min(abs(latmin-lat));
    latmin = lat(i);
    [~, i] = min(abs(latmax-lat));
    latmax = lat(i);
    [~, i] = min(abs(lonmin-lon));
    lonmin = lon(i);
    [~, i] = min(abs(lonmax-lon));
    lonmax = lon(i);
    % The pos/neg parts of lat and lon are needed because matlab doesn't
    % like plotting the data otherwise
    latmask_pos = lat >= latmin & lat <= latmax & lat >= 0;
    latmask_neg = lat >= latmin & lat <= latmax & lat < 0;
    lonmask_pos = lon >= lonmin & lon <= lonmax & lon >= 0;
    lonmask_neg = lon >= lonmin & lon <= lonmax & lon < 0;
    lat = [lat(latmask_neg); lat(latmask_pos)];
    lon = [lon(lonmask_neg); lon(lonmask_pos)];
    ssh = [ssh(latmask_neg, lonmask_neg, :) ...
        ssh(latmask_neg, lonmask_pos, :); ...
        ssh(latmask_pos, lonmask_neg, :) ...
        ssh(latmask_pos, lonmask_pos, :)];
    contour_mask = [contour_mask(latmask_neg, lonmask_neg, :) ...
        contour_mask(latmask_neg, lonmask_pos, :); ...
        contour_mask(latmask_pos, lonmask_neg, :) ...
        contour_mask(latmask_pos, lonmask_pos, :)];

    % Subset tracks and make daterefs
    daterefs_cell = cell(size(tracks_cell));
    for i = 1:length(tracks_cell)
        tracks_cell{i} = subset_tracks(tracks_cell{i}, latmin, latmax, ...
            lonmin, lonmax);
        daterefs_cell{i} = mk_dateref(tracks_cell{i}, dates);
    end
    
    latlim = [latmin latmax];
    lonlim = [lonmin lonmax];

    save(dest, 'daterefs_cell', 'ssh', 'dates', 'lat', 'lon', ...
        'contour_mask', 'tracks_cell', 'tracks_names', 'latlim', 'lonlim');
end

function [ ss ] = subset_tracks(tracks, latmin, latmax, lonmin, lonmax)
    ss = cell(size(tracks));
    pos = 1;
    for i = 1:length(tracks)
        track = tracks{i};
        track = track(track(:,1) >= latmin & track(:,1) <= latmax & ...
            track(:,2) >= lonmin & track(:,2) <= lonmax,:);
        if isempty(track)
            continue;
        end
        ss{pos} = track;
        pos = pos + 1;
    end
    ss = ss(1:pos-1);
end
