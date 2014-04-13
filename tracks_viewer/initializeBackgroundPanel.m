function initializeBackgroundPanel( horizontalBar, leftBottom, panelSize, hdls, fontSize, background_data )
%INITIALIZEBACKGROUNDPANEL Initialize background panel with background dropdown list, min and max background value,
%auto-adjusting_colorbar button

hdls.background_data = background_data;
hdls.is_autoadjusting_background = true;
background_readable_list = ['None' {background_data.name}];

for i = 1:length(background_data)
    hdls.background_data(i).date_index = 0;
    hdls.background_data(i).data = [];
    if hdls.background_data(i).dir(end) ~= '/'
        hdls.background_data(i).dir = [background_data(i).dir '/'];
    end
end

backgroundPanel = uipanel(horizontalBar, ...
    'Units', 'normalized', ...
    'Position', [leftBottom panelSize]);

uicontrol(backgroundPanel, ...
    'Style', 'text', ...
    'String', 'Choose background', ...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 0.5 1 0.5]);

uicontrol(backgroundPanel, ...
    'String', background_readable_list, ...
    'Style', 'popup',...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 0 1 0.5], ...
    'Callback', {@backgroundPopupCallback, hdls});
end

function backgroundPopupCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

background_index = get(hObject, 'Value');
if background_index == 1 % NONE
    hdls.plotting_background_index = 0;
else
    hdls.plotting_background_index = background_index - 1;
end

hdls.update_background();

end_busy_pointer(hdls, old_pointer);

end