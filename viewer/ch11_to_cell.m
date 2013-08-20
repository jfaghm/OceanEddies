function [ ch11_tracks ] = ch11_to_cell(chelton_results, dates, cyc)
%CH11_TO_CELL Helper function for converting from chelton's matrix format
%(preconverted to a matlab mat file) to our track format.
    chelton_results = chelton_results(ch11.chelton_results(:,5) == cyc,:);
    chelton_tracki = chelton_results(:,1);
    starti = min(chelton_tracki);
    endi = max(chelton_tracki);
    ch11_tracks = cell(1, endi-starti+1);
    parfor i = starti:endi
        ch11_track = chelton_results(chelton_tracki == i,2:4);
        for j = 1:size(ch11_track,1)
            ch11_track(j,3) = find(dates == ch11_track(j,3));
        end
        ch11_tracks{i} = ch11_track;
    end
end