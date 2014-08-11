function [ hdls ] = tracks_viewer( dates, track_data, background_data, ...
    pixel_dir, track_indexes, eddy_attribute_data, eddy_attribute_dir, eddy_plotting_data, chelton_eddies )
%TRACKS_VIEWER Start the eddy viewers with the following components
%   Current date box: display current date that the data will be plotted
%   Eddy type box: what type of eddies that will be plotted   
%   Track type: what type of tracks will be plotted
%   Track length: minimum and maximum length of the tracks which will be plotted
%   Backgrond panel:
%       Dropdown box: select what background will be plotted
%       Min value, max value edit box: min and max values of the background data which will be plotted
%       Auto panel: auto adjusting background values when zoomed in/out
%   Show contours: whether or not showing eddies' contour
%   Show hurricanes: whether or not showing hurricanes
%   Select eddy button: select an eddy on the map to see more information of that eddy

hdls = ViewerHandle();
hdls.dates = dates;
hdls.track_data = track_data;
hdls.pixel_dir = pixel_dir;
hdls.track_indexes = track_indexes;
hdls.attribute_dir = eddy_attribute_dir;
hdls.eddy_attribute_data = eddy_attribute_data;
hdls.chelton_eddies = chelton_eddies;

hdls.constants.eddy_types = eddy_plotting_data.eddy_types;
hdls.constants.eddy_markers = eddy_plotting_data.eddy_markers;
hdls.constants.eddy_colors = eddy_plotting_data.eddy_colors;
hdls.constants.eddy_type_names = eddy_plotting_data.eddy_type_names;

hdls.constants.PAST_TRACK_COLOR = [0 1 0];
hdls.constants.CYC_FUTURE_TRACK_COLOR = [0 0 1];
hdls.constants.ANT_FUTURE_TRACK_COLOR = [1 0 0];
hdls.constants.CHELTON_CYC_FUTURE_TRACK_COLOR = 'k';
hdls.constants.CHELTON_ANT_FUTURE_TRACK_COLOR = 'm';
hdls.constants.CHELTON_CURRENT_TRACK_COLOR = 'k';
hdls.constants.CHELTON_MARKER = 'd';

hdls.constants.CURRENT_EDDY_SIZE = 9;
hdls.constants.OTHER_EDDY_SIZE = 6;

hdls.constants.COAST_COLOR = [205 133 63] / 255;

horizontalBarFontSize = 12;

%% Initialize GUI Components
hdls.fig = figure('Name', 'Tracks Viewer', ...
    'NumberTitle', 'off', ...
    'Units', 'normalized', ...
    'OuterPosition', [0 .05 1 .9], ...
    'NextPlot', 'replace');

set(hdls.fig,'toolbar','figure');
% Initialize map axes, set properties.
hdls.mapAx = axesm('pcarree', ...
    'Grid', 'on', ...
    'parallellabel', 'on', ...
    'meridianlabel', 'on',...
    'maplatlimit', [-90 90], ...
    'maplonlimit', [20 380]);
set(gca, ...
    'Units', 'normalized', ...
    'Position', [0 0 .85 .8]);

zoom_handle = zoom(hdls.fig);
set(zoom_handle,'ActionPostCallback',@postZoomCallback);
set(zoom_handle,'ActionPreCallback',@preZoomCallback);
mapLatLimit = getm(hdls.mapAx, 'maplatlimit');
mapLonLimit = getm(hdls.mapAx, 'maplonlimit');
[hdls.mapXLimit(1), hdls.mapYLimit(1)] = mfwdtran(mapLatLimit(1), mapLonLimit(1)); % The axis coordinates at which the map starts
[hdls.mapXLimit(2), hdls.mapYLimit(2)] = mfwdtran(mapLatLimit(2), mapLonLimit(2));
hdls.axisXLimit = [-4 4]; %Initial axis limits, will be used to figure out zoomed in region
hdls.axisYLimit = [-2 2];

colorbar();

hdls.coast_plot = draw_coast_line(hdls.mapAx, hdls.constants.COAST_COLOR);

hdls.currentDateIndex = 1;
initializeHorizontalBar();

initializeDateListBox(dates, hdls);

display_axis_legend();

%% GUI initialization functions
    function initializeHorizontalBar()
        width = .85;
        height = .075;
        separator = .005; % The distance between horizontal panels, corresponding to horizontal bar width
        horizontalBar = uipanel(hdls.fig, ...
            'Units', 'normalized', ...
            'Position', [0 .875 width height],...
            'BorderType', 'none', ...
            'BackgroundColor', [.8 .8 .8]);
        
        panel_width = 0.1;
        
        currentSize = [panel_width 1];
        currentLeftBottom = [0 0];
        initializeDateBoxPanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeEddyTypePanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeTrackTypePanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeLengthFilterPanel(horizontalBar, currentLeftBottom, currentSize, hdls);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeBackgroundPanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize, background_data);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeContourPanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeCheltonPanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
        
        lastSize = currentSize;
        lastLeftBottom = currentLeftBottom;
        currentSize = [panel_width 1];
        currentLeftBottom = ...
            [(lastLeftBottom(1) + lastSize(1) + separator) 0];
        initializeSelectEddyPanel(horizontalBar, currentLeftBottom, currentSize, hdls, horizontalBarFontSize);
    end

    function preZoomCallback(~, ~)
    end

    function postZoomCallback(~, evd)
        hdls.axisXLimit = get(evd.Axes, 'XLim');
        hdls.axisYLimit = get(evd.Axes, 'YLim');
        if hdls.is_autoadjusting_background
            hdls.update_background();
        end
    end

    function display_axis_legend()
        % Create dumb plot objects to legend plots on the map
        
        cyc_past_track_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.PAST_TRACK_COLOR, ...
            'Parent', hdls.mapAx);
        cyc_future_track_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.CYC_FUTURE_TRACK_COLOR, ...
            'Parent', hdls.mapAx);
        ant_future_track_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.ANT_FUTURE_TRACK_COLOR, ...
            'Parent', hdls.mapAx);
        chelton_cyc_future_track_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.CHELTON_CYC_FUTURE_TRACK_COLOR, ...
            'Parent', hdls.mapAx);
        chelton_ant_future_track_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.CHELTON_ANT_FUTURE_TRACK_COLOR, ...
            'Parent', hdls.mapAx);        
        
        eddy_plots = zeros(1, length(hdls.constants.eddy_types));
        for i = 1:length(hdls.constants.eddy_type_names)
            eddy_plots(i) = plotm([NaN NaN], ...
                'Color', hdls.constants.eddy_colors{i}, ...
                'marker', hdls.constants.eddy_markers{i}, ...
                'LineStyle', 'None', ...
                'Parent', hdls.mapAx);
        end
        
        chelton_eddy_plot = plotm([NaN NaN], ...
            'Color', hdls.constants.CHELTON_CURRENT_TRACK_COLOR, ...
            'Marker', hdls.constants.CHELTON_MARKER, ...
            'LineStyle', 'None');
            
        
        legend_names{1} = 'Coast';
        legend_names{2} = 'Tracks in the past';
        legend_names{3} = 'Future cyclonic tracks';
        legend_names{4} = 'Future anticyclonic tracks';
        legend_names{5} = 'Chelton future cyclonic tracks';
        legend_names{6} = 'Chelton future anticyclonic tracks';
        for i = 1:length(eddy_plots)
            legend_names{6 + i} = [hdls.constants.eddy_type_names{i} ' features'];
        end
        legend_names{end + 1} = 'Chelton features';
            
        legend( [hdls.coast_plot cyc_past_track_plot cyc_future_track_plot ant_future_track_plot ...
            chelton_cyc_future_track_plot chelton_ant_future_track_plot eddy_plots chelton_eddy_plot], ...
            legend_names);
    end
end

