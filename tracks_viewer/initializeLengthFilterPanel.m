function initializeLengthFilterPanel( horizontalBar, leftBottom, panelSize, hdls )
%INITIALIZELENGTHFILTERPANEL Initialize length filter panel with 2 edit boxes for min and max length of eddy tracks

lengthFilterPanel = uipanel(horizontalBar, ...
    'Units', 'normalize', ...
    'Position', [leftBottom panelSize]);

uicontrol(lengthFilterPanel, ...
    'String', 'Min length', ...
    'Style', 'text',...
    'FontSize', 11, ...
    'Units', 'normalized', ...
    'Position', [0 .5 .5 .5]);

uicontrol(lengthFilterPanel, ...
    'String', 'Max length', ...
    'Style', 'text',...
    'FontSize', 11, ...
    'Units', 'normalized', ...
    'Position', [.5 .5 .5 .5]);

uicontrol(lengthFilterPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized',...
    'Position', [0 0 .5 .5], ...
    'String', 'any', ...
    'Callback', {@minLengthCallback, hdls});

uicontrol(lengthFilterPanel, ...
    'Style', 'edit', ...
    'Units', 'normalized',...
    'Position', [0.5 0 .5 .5], ...
    'String', 'any', ...
    'Callback', {@maxLengthCallback, hdls});

hdls.add_attribute_filter('lifetimes');

end


function minLengthCallback(hObject, ~, hdls)
% Update track min length and generate data again

old_pointer = start_busy_pointer(hdls);

minLength = get(hObject, 'String');
if isempty(minLength) || strcmp(minLength, 'any')
    hdls.set_attribute_filter_min_value('lifetimes', -inf);
else
    minLength = str2double(minLength);
    if(isnan(minLength)) % Not valid string
        errordlg('Min length must be an integer, "any" or empty', 'Min length input error');
        return;
    end
    hdls.set_attribute_filter_min_value('lifetimes', minLength);
end
hdls.generate_data();

end_busy_pointer(hdls, old_pointer);

end


function maxLengthCallback(hObject, ~, hdls)
% Update track max length and generate data again

old_pointer = start_busy_pointer(hdls);

maxLength = get(hObject, 'String');
if(isempty(maxLength) || strcmp(maxLength, 'any'))
    hdls.set_attribute_filter_max_value('lifetimes', inf);
else
    maxLength = str2double(maxLength);
    if(isnan(maxLength)) % Not valid string
        errordlg('Max length must be an integer, "any" or empty', 'Max length input error');
        return;
    end
    hdls.set_attribute_filter_max_value('lifetimes', maxLength);
end
hdls.generate_data();

end_busy_pointer(hdls, old_pointer);

end
