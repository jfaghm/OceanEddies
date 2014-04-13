function initializeContourPanel( horizontalBar, left_bottom, panel_size, hdls, fontSize )
%INITIALIZECONTOURPANEL Initialize contour panel where user can press contour button to choose to display eddies'
%contours or not

contourToggleButtonPanel = uipanel(horizontalBar, ...
    'Units', 'normalized', ...
    'Position', [left_bottom panel_size]);

uicontrol(contourToggleButtonPanel,...
    'Style', 'togglebutton', ...
    'String', 'Show Contours', ...
    'Units', 'normalized',...
    'Position', [0 0 1 1], ...
    'FontSize', fontSize, ...
    'Callback', {@contourToggleCallback, hdls});

end

function contourToggleCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

if get(hObject, 'Value') == get(hObject, 'Max')
    hdls.is_plotting_contour = true;
else
    hdls.is_plotting_contour = false;
end

hdls.update_contour();

end_busy_pointer(hdls, old_pointer);

end