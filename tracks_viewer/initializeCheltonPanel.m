function initializeCheltonPanel( horizontalBar, left_bottom, panel_size, hdls, fontSize )
%INITIALIZECHELTONPANEL Initialize a chelton panel, where user can choose to whether display chelton tracks
%   Detailed explanation goes here

cheltonToggleButtonPanel = uipanel(horizontalBar, ...
    'Units', 'normalized', ...
    'Position', [left_bottom panel_size]);

uicontrol(cheltonToggleButtonPanel,...
    'Style', 'togglebutton', ...
    'String', 'Show Chelton tracks', ...
    'Units', 'normalized',...
    'Position', [0 0 1 1], ...
    'FontSize', fontSize, ...
    'Callback', {@cheltonToggleCallback, hdls});

end

function cheltonToggleCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

if get(hObject, 'Value') == get(hObject, 'Max')
    hdls.is_plotting_chelton = true;
else
    hdls.is_plotting_chelton = false;
end
hdls.update_chelton_tracks();

end_busy_pointer(hdls, old_pointer);

end