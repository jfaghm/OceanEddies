function [ old_tracks ] = export_tracks_mat( tracks )
%EXPORT_TRACKS_MAT Will convert from new track format to old matrix based
% tracks: new, struct based tracks list
    old_tracks = cell(size(tracks));
    for i = 1:length(tracks)
        old = zeros(tracks(i).Length, 4);
        old(:,1) = [tracks(i).Frames.Lat];
        old(:,2) = [tracks(i).Frames.Lon];
        old(:,3) = double(tracks(i).StartIndex)+(1:tracks(i).Length)-1;
        old(:,4) = NaN;
        old_tracks{i} = old;
    end
end

