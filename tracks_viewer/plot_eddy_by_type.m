function plots = plot_eddy_by_type( view_handle, tracks, types, markers, colors, marker_size, is_filled )
%PLOT_EDDY_BY_TYPE Plot eddies with different specifications for different types of eddies
%   Detailed explanation goes here

plots = NaN(size(types));

for i = 1:length(types)
    if ~isempty(tracks)
        eddies = tracks(tracks(:, 3) == types(i), 1:2);
    else
        eddies = [];
    end
    eddy_plot = plot_eddies(view_handle.mapAx, eddies, markers{i}, ...
        colors{i}, marker_size, is_filled);
    plots(i) = eddy_plot;
end

end

function eddy_plot_handle = ...
        plot_eddies(axis_handle, eddy_bodies, marker, color, marker_size, is_filled)
% Plot the eddies on the world map
    if isempty(eddy_bodies)
        eddy_plot_handle = plotm([NaN NaN],...
                    'Color', color,...
                    'Marker', marker,...
                    'MarkerSize', marker_size,...
                    'Parent', axis_handle,...
                    'LineStyle', 'none');

        return;
    end

    if is_filled
        marker_face_color = color;
    else
        marker_face_color = 'none';
    end

    eddy_plot_handle = plotm(eddy_bodies(:, 1:2),...
                    'Color', color,...
                    'Marker', marker,...
                    'MarkerSize', marker_size,...
                    'MarkerFaceColor', marker_face_color,...
                    'Parent', axis_handle,...
                    'LineStyle', 'none');
end
