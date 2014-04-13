function initializeEddyTypePanel( horizontalBar, bottom_left, panel_size, hdls, fontSize )
%INITIALIZEEDDYTYPEPANEL Initialize eddy type panel, where user can choose to display cyclonic eddies or anticyclonic
%eddies or both of them

eddyTypePanel = uipanel(horizontalBar, 'Units', 'normalized', ...
    'Position', [bottom_left panel_size], 'BorderType', 'None');

uicontrol(eddyTypePanel, ...
    'String', 'Cyclonic Eddies', ...
    'Style', 'checkbox',...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 .5 1 .5], ...
    'Callback', {@cyclonicCheckboxCallback, hdls});

uicontrol(eddyTypePanel, ...
    'String', 'Anticyclonic Eddies', ...
    'Style', 'checkbox',...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 0 1 .5], ...
    'Callback', {@anticyclonicCheckboxCallback, hdls});

end

function cyclonicCheckboxCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

if(get(hObject, 'Value') == get(hObject, 'Max'))
    hdls.is_plotting_cyclonic = true;
else
    hdls.is_plotting_cyclonic = false;
end
hdls.update_cyc_tracks();

end_busy_pointer(hdls, old_pointer);

end

function anticyclonicCheckboxCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

if(get(hObject, 'Value') == get(hObject, 'Max'))
    hdls.is_plotting_anticyclonic = true;
else
    hdls.is_plotting_anticyclonic = false;
end
hdls.update_ant_tracks();

end_busy_pointer(hdls, old_pointer);

end