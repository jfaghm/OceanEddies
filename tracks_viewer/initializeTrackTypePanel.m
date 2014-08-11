function initializeTrackTypePanel( horizontalBar, leftBottom, panelSize, hdls, fontSize )
%INITIALIZETRACKTYPEPANEL Initialize track type panel with a dropdown list of different track type

track_type_readable_list = { 'All', 'None'};

is_none = @(tag) 0;
is_all = @(tag) 1;

filter_functions = {is_all, is_none};

trackTypePanel = uipanel(horizontalBar, ...
    'Units', 'normalized', ...
    'Position', [leftBottom panelSize], ...
    'BorderType', 'None');

uicontrol(trackTypePanel, ...
    'String', 'Track type', ...
    'Style', 'text',...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 .5 1 .5]);

uicontrol(trackTypePanel, ...
    'String', track_type_readable_list, ...
    'Style', 'popup',...
    'Units', 'normalized', ...
    'FontSize', fontSize, ...
    'Position', [0 0 1 .5], ...
    'Callback', {@trackTypeBoxCallback, hdls, filter_functions});

hdls.track_type_filter_function = is_all;
end

function trackTypeBoxCallback(hObject, ~, hdls, filter_functions)

track_type_index = get(hObject, 'Value');
switch track_type_index
    case 1 % ALL
        hdls.is_plotting_all = true;
        hdls.is_plotting_none = false;
    case 2 % NONE
        hdls.is_plotting_none = true;
        hdls.is_plotting_all = false;
    otherwise
        hdls.track_type_filter_function = filter_functions{track_type_index};
        hdls.is_plotting_all = false;
        hdls.is_plotting_none = false;
end

hdls.generate_data();

end