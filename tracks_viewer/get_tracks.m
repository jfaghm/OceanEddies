function [ past_tracks, future_tracks ] = get_tracks( curr_tracks, curr_tags, curr_date_index )
%GET_TRACKS Summary of this function goes here
%   Detailed explanation goes here

% Getting the current eddy indexes in tracks and track length
track_lengths = cellfun(@(x) size(x, 1), curr_tracks);

curr_eddy_indexes = zeros(size(track_lengths));
for i = 1:length(curr_tracks)
    curr_eddy_indexes(i) = find(curr_tracks{i}(:, 3) == curr_date_index, 1);
end

% Pre-allocate past_tracks and future_tracks
past_tracks = nan(sum(curr_eddy_indexes) + length(curr_tracks), 3);
future_tracks = nan(sum(track_lengths) - sum(curr_eddy_indexes) +  2 * length(curr_tracks), 3);

next_future_track_index = 1;
next_past_track_index = 1;
for i = 1:length(curr_tracks)
    curr_track = curr_tracks{i};
    curr_tag = curr_tags{i};
    curr_eddy_index = curr_eddy_indexes(i);
    
    past_tracks(next_past_track_index:(next_past_track_index + curr_eddy_index - 1), 1:2) = ...
        curr_track(1:curr_eddy_index, 1:2);
    past_tracks(next_past_track_index:(next_past_track_index + curr_eddy_index - 1), 3) = ...
        curr_tag(1:curr_eddy_index);
    next_past_track_index = next_past_track_index + curr_eddy_index + 1;
    
    future_tracks(next_future_track_index:(next_future_track_index + track_lengths(i) - curr_eddy_index), 1:2) = ...
        curr_track(curr_eddy_index:end, 1:2);
    
    future_tracks(next_future_track_index:(next_future_track_index + track_lengths(i) - curr_eddy_index), 3) = ...
        curr_tag(curr_eddy_index:end);
    next_future_track_index = next_future_track_index + track_lengths(i) - curr_eddy_index + 2;
end

end

