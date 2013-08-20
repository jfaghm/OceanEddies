function mk_all_daterefs(dates)
%MK_ALL_DATEREFS Will produce all daterefs needed
    tracks_cell = load('global/tracks');
    tracks_cell = tracks_cell.tracks_cell;

    daterefs_cell = cell(size(tracks_cell));
    for i = 1:length(tracks_cell)
        daterefs_cell{i} = mk_dateref(tracks_cell{i}, dates);
    end

    save('global/daterefs', 'daterefs_cell');
end