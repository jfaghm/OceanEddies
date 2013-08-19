function [ old_tracks ] = export_tracks_mat( tracks )
%EXPORT_TRACKS_MAT Will convert from new track format to old matrix based
% tracks: new, struct based tracks list
    old_tracks = cell(size(tracks));
    for i = 1:length(tracks)
        old_tracks{i} = [tracks(i).Eddies.Lat ...
            tracks(i).Eddies.Lon ...
            double(tracks(i).StartIndex)+(0:tracks(i).Length-1)' ...
            nan(tracks(i).Length, 1)];
    end
end

