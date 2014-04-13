function initializeSelectEddyPanel( horizontalBar, left_bottom, panel_size, hdls, fontSize )
%INITIALIZESELECTEDDYPANEL Initialize select eddy button so use can select and eddy and information will be displayed

eddySelectButtonPanel = uipanel(horizontalBar, ...
    'Units', 'normalized', ...
    'Position', [left_bottom panel_size]);

uicontrol(eddySelectButtonPanel,...
    'Style', 'pushbutton', ...
    'String', 'Select eddy', ...
    'Units', 'normalized',...
    'Position', [0 0 1 1], ...
    'FontSize', fontSize, ...
    'Callback', {@eddy_select_button_Callback, hdls});

hdls.add_displaying_attribute('Lat', 'lats');
hdls.add_displaying_attribute('Lon', 'lons');
hdls.add_displaying_attribute('Amplitude', 'amps');
hdls.add_displaying_attribute('Area', 'pxcounts');
hdls.add_displaying_attribute('Geodesic speed', 'geospeeds');

end

function eddy_select_button_Callback(~, ~, hdls)

old_pointer = start_busy_pointer(hdls);

[selected_lat, selected_lon] = inputm(1);

if isempty(hdls.ant_current_eddies) && isempty(hdls.cyc_current_eddies)
    error('No eddies was plotted yet');
end

% Getting the closest eddy on map based on user's input
if isempty(hdls.cyc_current_eddies)
    cyc_d = inf;
else
    cyc_d = distance(hdls.cyc_current_eddies(:, 1), hdls.cyc_current_eddies(:, 2), selected_lat, selected_lon);
end

if isempty(hdls.ant_current_eddies)
    ant_d = inf;
else
    ant_d = distance(hdls.ant_current_eddies(:, 1), hdls.ant_current_eddies(:, 2), selected_lat, selected_lon);
end

if min(cyc_d(:)) < min(ant_d(:))
    d = cyc_d;
    plotting_eddy_indexes = hdls.cyc_plotting_eddy_indexes;
    track_indexes = hdls.track_indexes.cyc_track_indexes{hdls.currentDateIndex};
    hdls.chosen_eddy.type = 'cyc';
    
else
    d = ant_d;
    plotting_eddy_indexes = hdls.ant_plotting_eddy_indexes;
    track_indexes = hdls.track_indexes.ant_track_indexes{hdls.currentDateIndex};
    hdls.chosen_eddy.type = 'ant';
end

% Index of the closest eddy
k = find(d == min(d(:)), 1);

hdls.chosen_eddy.eddy_index = plotting_eddy_indexes(k);
hdls.chosen_eddy.track_index = track_indexes(hdls.chosen_eddy.eddy_index);
hdls.is_any_eddy_selected = true;

hdls.update_eddy_info();

end_busy_pointer(hdls, old_pointer);
end