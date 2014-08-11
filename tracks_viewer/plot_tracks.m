function [past_track_plot, future_track_plot, other_eddy_plots] = ...
    plot_tracks( hdls, past_tracks, future_tracks, past_track_color, future_track_color )
%PLOT_TRACKS Plot past tracks, future tracks and eddies in the past and future (not the current ones)

if isempty(past_tracks)
    past_tracks = [NaN NaN NaN]; % Plotm requires the input to be not empty
end
past_track_plot =  plotm(past_tracks(:, 1:2), 'Color', past_track_color, 'Parent', hdls.mapAx);

if isempty(future_tracks)
    future_tracks = [NaN NaN NaN]; % Plotm requires the input to be not empty
end
future_track_plot =  plotm(future_tracks(:, 1:2), 'Color', future_track_color, 'Parent', hdls.mapAx);

% Plot other eddies by types
other_eddy_plots = plot_eddy_by_type(hdls, [past_tracks;future_tracks], hdls.constants.eddy_types, ...
    hdls.constants.eddy_markers, hdls.constants.eddy_colors, hdls.constants.OTHER_EDDY_SIZE, false);

end

