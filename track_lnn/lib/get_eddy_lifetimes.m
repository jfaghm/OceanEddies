function [ eddy_lifetimes ] = get_eddy_lifetimes( eddy_counts, tracks  )
%GET_EDDY_LIFETIMES Summary of this function goes here
%   Detailed explanation goes here

eddy_lifetimes = cell(size(eddy_counts));
for i = 1:length(eddy_counts)
    eddy_lifetimes{i} = ones(1, eddy_counts(i));
end

for i = 1:length(tracks)
    curr_track = tracks{i};
    track_length = size(curr_track, 1);
    for j = 1:size(curr_track, 1)
        curr_date_index = curr_track(j, 3);
        curr_eddy_index = curr_track(j, 4);
        eddy_lifetimes{curr_date_index}(curr_eddy_index) = track_length;
    end
end

end

