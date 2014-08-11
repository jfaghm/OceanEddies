function [ old_tracks ] = export_tracks_old( tracks )
%EXPORT_TRACKS_OLD Will convert from new track format to old matrix based
%format used by LNN. (Index field produced by this function is invalid)
% tracks: new, struct based tracks list
    old_tracks = cell(1, length(tracks));
    for i = 1:length(tracks)
        old_tracks{i} = [tracks(i).Eddies.Lat ...
            tracks(i).Eddies.Lon ...
            double(tracks(i).StartIndex)+double((0:tracks(i).Length-1)') ...
            nan(tracks(i).Length, 1)];
    end
end

