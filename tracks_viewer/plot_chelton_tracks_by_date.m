function [curr_plot, past_plot, future_plot] = plot_chelton_tracks_by_date( chelton_tracks, chelton_date_indexes, ...
    curr_date_index, marker, current_color, past_color, future_color, min_lifetime, max_lifetime)
%PLOT_CHELTON_TRACKS_BY_DATE Plot chelton tracks in different colors for the eddies at current, before and after date 
%index
%Parameters:
%   chelton_tracks: a cell array of chelton tracks in format [lat lon date_index id]
%   chelton_date_indexes: a cell array of indexes of chelton tracks that have an eddy at current timestep
%   curr_date_index: only the eddys that have a timestep at curr_date_index will be plotted on the map
%   marker: chelton eddy's marker
%   current_color: color of current eddy
%   past_color: color of eddies and tracks in the past
%   future_color: color of eddies and tracks in the future
%   min_lifetime: minimum lifetime of plotting eddies
%   max_lifetime: maximum lifetime of plotting eddies


line_width = 0.5;

curr_tracks = chelton_tracks(chelton_date_indexes{curr_date_index});
track_lengths = cellfun(@(x) size(x, 1), curr_tracks);
curr_tracks = curr_tracks(track_lengths >= min_lifetime & track_lengths <= max_lifetime);
track_lengths = track_lengths(track_lengths >= min_lifetime & track_lengths <= max_lifetime);

if isempty(curr_tracks)
    past_tracks = [NaN NaN];
    future_tracks = [NaN NaN];
    curr_eddies = [NaN NaN];
else
    [past_tracks, future_tracks, curr_eddies] = get_tracks(curr_tracks, track_lengths, curr_date_index);
end
past_plot = plotm(past_tracks, ...
    'Marker', marker, ...
    'Color', past_color, ...
    'LineWidth', line_width);

future_plot = plotm(future_tracks, ...
    'marker', marker, ...
    'Color', future_color, ...
    'LineWidth', line_width);

curr_plot = plotm(curr_eddies, ...
    'Marker', marker, ...
    'Color', current_color, ...
    'LineWidth', line_width, ...
    'MarkerFaceColor', current_color, ...
    'MarkerSize', 9,...
    'LineStyle', 'none');

end

function [past_tracks, future_tracks, curr_eddies] = get_tracks(curr_tracks, track_lengths, curr_date_index)

curr_eddy_indexes = zeros(size(track_lengths));
curr_eddies = zeros(length(curr_tracks), 2);
for i = 1:length(curr_tracks)
    curr_eddy_indexes(i) = find(curr_tracks{i}(:, 3) == curr_date_index, 1);
    curr_eddies(i, 1) = curr_tracks{i}(curr_eddy_indexes(i), 1);
    curr_eddies(i, 2) = curr_tracks{i}(curr_eddy_indexes(i), 2);
end

% Pre-allocate past_tracks and future_tracks
past_tracks = nan(sum(curr_eddy_indexes) + length(curr_tracks), 2);
future_tracks = nan(sum(track_lengths) - sum(curr_eddy_indexes) +  2 * length(curr_tracks), 2);

next_future_track_index = 1;
next_past_track_index = 1;
for i = 1:length(curr_tracks)
    curr_track = curr_tracks{i};
    curr_eddy_index = curr_eddy_indexes(i);
    
    past_tracks(next_past_track_index:(next_past_track_index + curr_eddy_index - 1), 1:2) = ...
        curr_track(1:curr_eddy_index, 1:2);
    next_past_track_index = next_past_track_index + curr_eddy_index + 1;
    
    future_tracks(next_future_track_index:(next_future_track_index + track_lengths(i) - curr_eddy_index), 1:2) = ...
        curr_track(curr_eddy_index:end, 1:2);
    
    next_future_track_index = next_future_track_index + track_lengths(i) - curr_eddy_index + 2;
end

end