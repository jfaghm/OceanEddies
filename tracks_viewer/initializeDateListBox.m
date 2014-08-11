function initializeDateListBox( dates, hdls )
%INITIALIZEDATELISTBOX Initialize date list box:
%   dateListBox: a list of dates in format yyyymmdd for the user to select
%   generateDataButton: a button to generate data
%   forward/backward buttons: buttons to move forward/backward in time
%   Detailed explanation goes here

% Create list box for choosing date to display eddies
date_list = arrayfun(@num2str, dates, 'UniformOutput', false);

dateListBox = uicontrol(hdls.fig, ...
    'Style', 'listbox', ...
    'Units', 'normalized', ...
    'String', date_list, ...
    'Position', [0.875 .6 .1 .4], ...
    'Callback', {@dateListBoxCallback, hdls});

% Forward button
uicontrol(hdls.fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'String', 'Forward', ...
    'Callback', {@forward_button_Callback, dateListBox, hdls}, ...
    'position', [0.925 0.33 .05 .05]);

% backward button
uicontrol(hdls.fig, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'String', 'Backward', ...
    'Callback', {@backward_button_Callback, dateListBox, hdls}, ...
    'position', [0.875 0.33 .05 .05]);

hdls.eddyInfoText = uicontrol(hdls.fig, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'String', 'Eddy Information', ...
    'position', [0.875 0 0.1 .3]);
end

function dateListBoxCallback(hObject, ~, hdls)

old_pointer = start_busy_pointer(hdls);

hdls.currentDateIndex = get(hObject, 'Value');
hdls.generate_data();

end_busy_pointer(hdls, old_pointer);

end

function forward_button_Callback(~, ~, dateListBox, hdls)

old_pointer = start_busy_pointer(hdls);

curr_date_index = get(dateListBox, 'Value');
if(curr_date_index == length(get(dateListBox, 'String')))
    return;
end
set(dateListBox, 'Value', curr_date_index + 1);
hdls.currentDateIndex = hdls.currentDateIndex + 1;
hdls.generate_data();

end_busy_pointer(hdls, old_pointer);

end


function backward_button_Callback(~, ~, dateListBox, hdls)

old_pointer = start_busy_pointer(hdls);

if hdls.currentDateIndex == 1
    return;
end
hdls.currentDateIndex = hdls.currentDateIndex - 1;
set(dateListBox, 'Value', hdls.currentDateIndex);
hdls.generate_data();

end_busy_pointer(hdls, old_pointer);

end