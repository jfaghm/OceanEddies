classdef ViewerHandle < handle
    %VIEWERHANDLE Contains the plots data and logic of the track viewer
    
    properties
        fig % main figure of the viewer
        mapAx % axis of the map
        mapXLimit = [0; 0]  % Axis x limit of the map at bottom left and upper right of the map on the axis
        mapYLimit = [0; 0]  % Axis y limit of the map at bottom left and upper right of the map on the axis
        axisXLimit % Axis x limit when zoomed in/out
        axisYLimit % Axis y limit when zoomed in/out
        coast_plot = [] % Plot of the coast
        dates
        currentDateIndex % the index of the date that is currently used to plot data
        
        dateTextBox % the text box displaying current date
        
        eddyInfoText % the text box displaying eddy'info
        
        track_data = [] % including track [lat lon date_index eddy_index] and tags for each eddy in the track
        pixel_dir % Pixel index directory of the eddies, will be use to plot eddy's contour
        
        % Track plotting flags
        is_plotting_all = true
        is_plotting_none = false
        track_type_filter_function = @(x) 1; % Function that will be use to filter out tracks

        % Maximum and minimum values of the background data
        minBackgroundValue = -inf
        maxBackgroundValue = inf
        background_data
        currentBackgroundData = []
        % index of the plotting background data
        plotting_background_index = 0
        is_autoadjusting_background = false % whether or not autoadjust background data to fit in current view
        background_plot = []; %plot of background
        
        
        % eddy_filters is a struct which will be to used to filter eddies to plot by attribute. All plotting eddies will
        % have attributes with values between eddy_filters.(attribute_name).min_value and
        % eddy_filters.(attribute_name).max_value
        eddy_filters = []
        
        % the directory to get eddies' attribute file, should be in format (cyc/ant)_(attribute_name).mat
        attribute_dir = []
        
        % Plotting constants, should have following attributes:
        %   PAST_TRACK_COLOR: color of the tracks in the past
        %   CYC_FUTURE_TRACK_COLOR: color of future cyclonic tracks
        %   ANT_FUTURE_TRACK_COLOR: color of future anticyclonic trakcs
        %   eddy_types: a list of different customized eddy types
        %   eddy_markers: a cell array of different markers for each eddy type
        %   eddy_colors: a cell array of different colors for each eddy type
        %   eddy_type_names: a cell array of names for each eddy type, will be used in the legend
        constants
        
        % Plotting flags
        is_plotting_cyclonic = false % whether or not to plot cyclonic eddies
        is_plotting_anticyclonic = false % whether or not to plot anticyclonic eddies

        is_plotting_contour = false % whether or not to plot contours of eddies
        is_watching_eddy = false % Whether or not to update chosen eddy's information when the data is generated again
        is_auto_zooming = false % whether or not to zoom in the current chosen eddy
        is_plotting_past_and_future = true % whether or not to plot eddies in the past and futures
        is_any_eddy_selected = false; % whether any eddy is selected
        
        % Plotting data
        cyc_plotting_eddy_indexes % index of current cyclonic plotting eddies in the eddy cell array
        cyc_current_eddies % [lat lon] of current cyclonic plotting eddies
        ant_plotting_eddy_indexes
        ant_current_eddies
        
        track_indexes = [] % track_indexes.(cyc/ant)_track_indexes will be cell array of every eddy's track indexes
        
        % eddy_attribute_data.(cyc/ant)_(attribute_name) will be cell array of eddies' attributes
        % Will be used to filter eddies and display eddy's info
        eddy_attribute_data = [];
        
        % Names of the eddy attributes that will be displayed in eddy info box
        displaying_eddy_attribute_names = [];
        % Readable name of the eddy attributes that will be displayed in eddy info box
        displaying_eddy_attribute_readable_names = [];
        
        % Info of chosen eddy:
        %   eddy_index: index of this eddy in eddy cell array
        %   type: 'cyc' or 'ant'
        %   track_index: track index of this eddy
        %   eddy_plot: a circle at the chosen eddy's position to differentiate it from other eddies
        chosen_eddy = [];
        
        % Plots
        cyc_current_eddy_plots = []; % plots of current cyclonic eddies with different types
        cyc_other_eddy_plots = []; % plots of cyclonic eddies in the past and in the futures with different types
        cyc_past_plots = []; % cyclonic past tracks plots
        cyc_future_plots = []; % cyclonic future tracks plots
        ant_current_eddy_plots = [];
        ant_other_eddy_plots = [];
        ant_past_plots = [];
        ant_future_plots = [];
        
        cyc_contour_plot = []; % plot of cyclonic eddies' contours
        ant_contour_plot = []; % plot of anticyclonic eddies' contours
        
        % Chelton data
        is_plotting_chelton = false;
        chelton_eddies = [] % chelton_eddies.(ant/cyc): dataset of cyclonic/anticylonic chelton eddies
        chelton_cyc_plots = struct % a struct with fields: past_plot, current_plot, future_plot
        chelton_ant_plots = struct % a struct with fields: past_plot, current_plot, future_plot
    end
    
    methods
        function hdls = ViewerHandle()
            hdls.chelton_cyc_plots.past_plot = [];
            hdls.chelton_cyc_plots.current_plot = [];
            hdls.chelton_cyc_plots.future_plot = [];
            hdls.chelton_ant_plots.past_plot = [];
            hdls.chelton_ant_plots.current_plot = [];
            hdls.chelton_ant_plots.future_plot = [];
        end
        
        function generate_data(hdls)
            % Generate all data on the map
            
            hdls.update_date_text_box();
            
            hdls.update_background_plot();
            
            hdls.update_tracks();
            
            if ~hdls.is_plotting_past_and_future
                hdls.clear_past_and_future_tracks();
            end
            
            hdls.update_eddy_info();
        end
        
        function update_tracks(hdls)
            % update cyclonic and anticyclonic tracks
            hdls.update_cyc_tracks();
            hdls.update_ant_tracks();
        end
        
        function update_cyc_tracks(hdls)
            % update cyclonic tracks
            hdls.clear_tracks('cyc');
            if hdls.is_plotting_cyclonic
                hdls.plot_cyc_tracks();
            end
            hdls.update_cyc_contour();
        end
        
        function update_ant_tracks(hdls)
            % update anticyclonic tracks
            hdls.clear_tracks('ant');
            if hdls.is_plotting_anticyclonic
                hdls.plot_ant_tracks();
            end
            hdls.update_ant_contour();
        end
        
        function update_chelton_tracks(hdls)
            % update chelton tracks
            hdls.clear_chelton_tracks('cyc');
            hdls.clear_chelton_tracks('ant');
            
            if hdls.is_plotting_chelton
                if hdls.is_plotting_cyclonic
                    hdls.plot_chelton_tracks('cyc');
                end
                
                if hdls.is_plotting_anticyclonic
                    hdls.plot_chelton_tracks('ant');
                end
            end
        end
        
        function plot_cyc_tracks(hdls)
            if hdls.is_plotting_chelton
                hdls.plot_chelton_tracks('cyc');
            end
            % update cyc_plotting_eddy_indexes, cyc_current_eddies, cyc_past_plots, cyc_future_plots,
            % cyc_other_eddy_plots, cyc_current_eddy_plots
            curr_track_indexes = hdls.track_indexes.cyc_track_indexes{hdls.currentDateIndex};
            curr_lats = hdls.eddy_attribute_data.cyc_lats{hdls.currentDateIndex};
            curr_lons = hdls.eddy_attribute_data.cyc_lons{hdls.currentDateIndex};
            curr_types = hdls.eddy_attribute_data.cyc_types{hdls.currentDateIndex};
            
            plotting_eddy_indexes = hdls.get_plotting_eddy_indexes('cyc');
            hdls.cyc_plotting_eddy_indexes = plotting_eddy_indexes;
            hdls.cyc_current_eddies = [curr_lats(plotting_eddy_indexes)' curr_lons(plotting_eddy_indexes)'];
            
            qualified_track_indexes_with_nan = curr_track_indexes(plotting_eddy_indexes);
            qualified_track_indexes = qualified_track_indexes_with_nan(~isnan(qualified_track_indexes_with_nan));
            curr_tracks = hdls.track_data.cyc_tracks(qualified_track_indexes);
            curr_tags = hdls.track_data.cyc_tags(qualified_track_indexes);
            
            [past_tracks, future_tracks] = get_tracks( curr_tracks, curr_tags, hdls.currentDateIndex );
            
            % Get eddy plots
            [ hdls.cyc_past_plots, hdls.cyc_future_plots, ...
                hdls.cyc_other_eddy_plots] = plot_tracks(hdls, past_tracks, future_tracks, ...
                hdls.constants.PAST_TRACK_COLOR, hdls.constants.CYC_FUTURE_TRACK_COLOR);
            
            hdls.cyc_current_eddy_plots = plot_eddy_by_type(hdls, [curr_lats(plotting_eddy_indexes)' ...
                curr_lons(plotting_eddy_indexes)' curr_types(plotting_eddy_indexes)'], hdls.constants.eddy_types, ...
                hdls.constants.eddy_markers, hdls.constants.eddy_colors, hdls.constants.CURRENT_EDDY_SIZE, false);
        end
        
        function plot_ant_tracks(hdls)
            if hdls.is_plotting_chelton
                hdls.plot_chelton_tracks('ant');
            end
            % update ant_plotting_eddy_indexes, ant_current_eddies, ant_past_plots, ant_future_plots,
            % ant_other_eddy_plots, ant_current_eddy_plots
            curr_track_indexes = hdls.track_indexes.ant_track_indexes{hdls.currentDateIndex};
            curr_lats = hdls.eddy_attribute_data.ant_lats{hdls.currentDateIndex};
            curr_lons = hdls.eddy_attribute_data.ant_lons{hdls.currentDateIndex};
            curr_types = hdls.eddy_attribute_data.ant_types{hdls.currentDateIndex};
            
            plotting_eddy_indexes = hdls.get_plotting_eddy_indexes('ant');
            
            hdls.ant_plotting_eddy_indexes = plotting_eddy_indexes;
            hdls.ant_current_eddies = [curr_lats(plotting_eddy_indexes)' curr_lons(plotting_eddy_indexes)'];
            qualified_track_indexes = curr_track_indexes(plotting_eddy_indexes);
            qualified_track_indexes = qualified_track_indexes(~isnan(qualified_track_indexes));
            curr_tracks = hdls.track_data.ant_tracks(qualified_track_indexes);
            curr_tags = hdls.track_data.ant_tags(qualified_track_indexes);
            
            [past_tracks, future_tracks] = get_tracks( curr_tracks, curr_tags, hdls.currentDateIndex );
            
            [ hdls.ant_past_plots, hdls.ant_future_plots, ...
                hdls.ant_other_eddy_plots] = plot_tracks(hdls, past_tracks, future_tracks, ...
                hdls.constants.PAST_TRACK_COLOR, hdls.constants.ANT_FUTURE_TRACK_COLOR);
            
            hdls.ant_current_eddy_plots = plot_eddy_by_type(hdls, [curr_lats(plotting_eddy_indexes)' ...
                curr_lons(plotting_eddy_indexes)' curr_types(plotting_eddy_indexes)'], hdls.constants.eddy_types, ...
                hdls.constants.eddy_markers, hdls.constants.eddy_colors, hdls.constants.CURRENT_EDDY_SIZE, false);
        end
        
        function clear_tracks(hdls, eddy_type)
            % Clear track plots: current_eddy_plots, other_eddy_plots, past_plots, future_plots
            if strcmp(eddy_type, 'cyc') || strcmp(eddy_type, 'cyclonic')
                plot_field_names = {'cyc_current_eddy_plots', 'cyc_other_eddy_plots', 'cyc_past_plots', 'cyc_future_plots'};
                curr_eddies_field_name = 'cyc_current_eddies';
            else
                plot_field_names = {'ant_current_eddy_plots', 'ant_other_eddy_plots', 'ant_past_plots', 'ant_future_plots'};
                curr_eddies_field_name = 'ant_current_eddies';
                
            end
            for plot_field_name = plot_field_names
                if ~isempty(hdls.(plot_field_name{1}))
                    for i = 1:length(hdls.(plot_field_name{1}))
                        if ~isempty(hdls.(plot_field_name{1})(i))
                            delete(hdls.(plot_field_name{1})(i));
                        end
                    end
                end
                hdls.(plot_field_name{1}) = [];
            end
            
            % Set current eddies to empty
            hdls.(curr_eddies_field_name) = [];
            
            hdls.clear_chelton_tracks(eddy_type);
            
        end
        
        function plotting_eddy_indexes = get_plotting_eddy_indexes(hdls, eddy_type)
            % Get plotting eddy indexes after applying eddy filter and track filter
            if strcmp(eddy_type, 'cyc');
                eddy_initial = 'cyc_';
                eddy_track_indexes = hdls.track_indexes.cyc_track_indexes;
                track_tags = hdls.track_data.cyc_tags;
            else
                eddy_initial = 'ant_';
                eddy_track_indexes = hdls.track_indexes.ant_track_indexes;
                track_tags = hdls.track_data.ant_tags;
            end
            
            curr_track_indexes = eddy_track_indexes{hdls.currentDateIndex};
            
            eddy_filter_names = fieldnames(hdls.eddy_filters);
            
            plotting_eddy_indexes = 1:length(curr_track_indexes);
            
            qualified_indexes = true(size(plotting_eddy_indexes));
            for i = 1:length(eddy_filter_names)
                curr_attribute_values = hdls.eddy_attribute_data.([eddy_initial eddy_filter_names{i}]){hdls.currentDateIndex};
                min_value = hdls.eddy_filters.([eddy_filter_names{i}]).min_value;
                max_value = hdls.eddy_filters.([eddy_filter_names{i}]).max_value;
                qualified_indexes = qualified_indexes & curr_attribute_values >= min_value & ...
                    curr_attribute_values <= max_value;
            end
            plotting_eddy_indexes = plotting_eddy_indexes(qualified_indexes);
            
            % Filter eddies by track's properties
            if hdls.is_plotting_all
                % No filter is applied
            elseif hdls.is_plotting_none
                plotting_eddy_indexes = [];
                return;
            else
                qualified_indexes = false(size(plotting_eddy_indexes));
                for i = 1:length(plotting_eddy_indexes)
                    curr_index = plotting_eddy_indexes(i);
                    track_index = curr_track_indexes(curr_index);
                    if isnan(track_index)
                        continue;
                    else
                        qualified_indexes(i) = ...
                            hdls.track_type_filter_function(track_tags{track_index}) == 1;
                    end
                end
                plotting_eddy_indexes = plotting_eddy_indexes(qualified_indexes);
            end
        end
        
        function plot_chelton_tracks(hdls, eddy_type)
            if strcmp(eddy_type, 'cyc')
                [hdls.chelton_cyc_plots.current_plot, hdls.chelton_cyc_plots.past_plot, ...
                    hdls.chelton_cyc_plots.future_plot] = ...
                    plot_chelton_tracks_by_date(hdls.chelton_eddies.cyc, hdls.chelton_eddies.cyc_date_indexes,...
                        hdls.currentDateIndex, ...
                        hdls.constants.CHELTON_MARKER, hdls.constants.CHELTON_CURRENT_TRACK_COLOR, ...
                        hdls.constants.PAST_TRACK_COLOR, hdls.constants.CHELTON_CYC_FUTURE_TRACK_COLOR, ...
                        hdls.eddy_filters.lifetimes.min_value, hdls.eddy_filters.lifetimes.max_value);
            else
                [hdls.chelton_ant_plots.current_plot, hdls.chelton_ant_plots.past_plot, ...
                    hdls.chelton_ant_plots.future_plot] = ...
                    plot_chelton_tracks_by_date(hdls.chelton_eddies.ant, hdls.chelton_eddies.ant_date_indexes, ...
                        hdls.currentDateIndex, ...
                        hdls.constants.CHELTON_MARKER, hdls.constants.CHELTON_CURRENT_TRACK_COLOR, ...
                        hdls.constants.PAST_TRACK_COLOR, hdls.constants.CHELTON_ANT_FUTURE_TRACK_COLOR, ...
                        hdls.eddy_filters.lifetimes.min_value, hdls.eddy_filters.lifetimes.max_value);
            end
        end
                
        function clear_chelton_tracks(hdls, eddy_type)
            % Clear chelton tracks if existed
            if strcmp(eddy_type, 'cyc') || strcmp(eddy_type, 'cyclonic')
                chelton_plot_name = 'chelton_cyc_plots';
            else
                chelton_plot_name = 'chelton_ant_plots';
            end
            if ~isempty(hdls.(chelton_plot_name))
                plot_field_names = {'current_plot', 'past_plot', 'future_plot'};
                for plot_name = plot_field_names
                    if ~isempty(hdls.(chelton_plot_name).(plot_name{1}))
                        delete(hdls.(chelton_plot_name).(plot_name{1}));
                    end
                    hdls.(chelton_plot_name).(plot_name{1}) = [];
                end
            end
        end
        
        function update_background(hdls)
            % Update hdls.background_plot and also contour if needed because contour values depend on background data
            
            hdls.update_background_plot();
            
            hdls.update_contour();
            
        end
        
        function update_background_plot(hdls)
            % plot background data
            if hdls.plotting_background_index == 0
                hdls.clear_background();
            else
                hdls.clear_background();
                curr_date = hdls.dates(hdls.currentDateIndex);
                curr_lat = hdls.background_data(hdls.plotting_background_index).lat;
                curr_lon = hdls.background_data(hdls.plotting_background_index).lon;
                
                if hdls.background_data(hdls.plotting_background_index).date_index ~= hdls.currentDateIndex
                    file_dir = hdls.background_data(hdls.plotting_background_index).dir;
                    file_initial = hdls.background_data(hdls.plotting_background_index).file_initial;
                    file_name = [file_dir file_initial '_' num2str(curr_date) '.mat'];
                    temp = load(file_name);
                    hdls.background_data(hdls.plotting_background_index).data = temp.data;
                    hdls.background_data(hdls.plotting_background_index).date_index = hdls.currentDateIndex;
                end
                
                [hdls.background_plot, hdls.currentBackgroundData] = plot_background_data(hdls, ....
                    hdls.background_data(hdls.plotting_background_index).data, curr_lat, curr_lon);
            end
        end        
        function clear_background(hdls)
            if ~isempty(hdls.background_plot)
                delete(hdls.background_plot);
                hdls.background_plot = [];
            end
            hdls.currentBackgroundData = [];
        end
        
        function update_contour(hdls)
            hdls.update_cyc_contour();
            hdls.update_ant_contour();
        end
        
        function update_cyc_contour(hdls)
            % update cyclonic eddies' contours
            if hdls.is_plotting_contour
                hdls.clear_cyc_contour();
                if hdls.is_plotting_cyclonic
                    hdls.cyc_contour_plot = plot_contour(hdls.dates(hdls.currentDateIndex), ...
                        hdls.pixel_dir, hdls.cyc_plotting_eddy_indexes, hdls.currentBackgroundData, 'cyc');
                end
            else
                hdls.clear_cyc_contour();
            end
        end
        
        function update_ant_contour(hdls)
            % update anticyclonic edides' contours
            if hdls.is_plotting_contour
                hdls.clear_ant_contour();
                if hdls.is_plotting_anticyclonic
                    hdls.ant_contour_plot = plot_contour(hdls.dates(hdls.currentDateIndex), ...
                        hdls.pixel_dir, hdls.ant_plotting_eddy_indexes, hdls.currentBackgroundData, 'ant');
                end
            else
                hdls.clear_ant_contour();
            end
        end
        
        function clear_ant_contour(hdls)
            % Clear anticyclonic eddies' contours
            if ~isempty(hdls.ant_contour_plot)
                delete(hdls.ant_contour_plot);
                hdls.ant_contour_plot = [];
            end
        end
        
        function clear_cyc_contour(hdls)
            % Clear cyclonic eddies' contours
            if ~isempty(hdls.cyc_contour_plot)
                delete(hdls.cyc_contour_plot);
                hdls.cyc_contour_plot = [];
            end
        end
        
        function zoom_in(hdls, lat, lon)
            % Zoom into a specific point on the map
            [curr_x, curr_y] = mfwdtran(lat, lon);
            new_x_limit = [(curr_x - 0.05) (curr_x + 0.05)];
            new_y_limit = [(curr_y - 0.025) (curr_y + 0.025)];
            set(hdls.mapAx, 'XLim', new_x_limit);
            set(hdls.mapAx, 'YLim', new_y_limit);
            hdls.axisXLimit = new_x_limit;
            hdls.axisYLimit = new_y_limit;
        end
        
        function reset_axis_limit(hdls)
            set(hdls.mapAx, 'XLimMode', 'auto');
            set(hdls.mapAx, 'YLimMode', 'auto');
        end
        
        function zoom_in_eddy(hdls, date_index, lat, lon)
            % Zoom in a eddy at date_index in time and (lat, lon) in space
            set(hdls.dateListBox, 'Value', date_index);
            hdls.currentDateIndex = date_index;
            hdls.generate_data();
            hdls.zoom_in(lat, lon);
        end
        
        function select_eddy(hdls, date_index, eddy_index, eddy_type)
            % Select an eddy by date index, eddy index and eddy type
            %   The plots will be updated to the date_index and eddy info will be displayed
            set(hdls.dateListBox, 'Value', date_index);
            hdls.currentDateIndex = date_index;
            hdls.chosen_eddy.eddy_index = eddy_index;
            hdls.chosen_eddy.type = eddy_type;
            hdls.chosen_eddy.track_index = hdls.get_eddy_track_index(date_index, eddy_index, eddy_type);
            hdls.is_any_eddy_selected = true;
            hdls.generate_data();
        end
        
        function update_eddy_info(hdls)
            % Clean up last chosen eddy's info if necessary, get the eddy index and display its info
            if ~isempty(hdls.chosen_eddy)
                if isfield(hdls.chosen_eddy, 'eddy_plot') &&  ~isempty(hdls.chosen_eddy.eddy_plot)
                    delete(hdls.chosen_eddy.eddy_plot);
                    hdls.chosen_eddy.eddy_plot = [];
                end
                
                if isfield(hdls.chosen_eddy, 'quiver_plot') && ~isempty(hdls.chosen_eddy.quiver_plot)
                    delete(hdls.chosen_eddy.quiver_plot);
                    hdls.chosen_eddy.quiver_plot = [];
                end
                
                set(hdls.eddyInfoText, 'String', '');
                
                % Get new eddy index if necessary
                if ~hdls.is_any_eddy_selected
                    if hdls.is_watching_eddy
                        if isnan(hdls.chosen_eddy.track_index)
                            % Last time a untracked eddy was selected
                            hdls.chosen_eddy.eddy_index = [];
                        else
                            if strcmp(hdls.chosen_eddy.type, 'cyc')
                                curr_track = hdls.track_data.cyc_tracks{hdls.chosen_eddy.track_index};
                            else
                                curr_track = hdls.track_data.ant_tracks{hdls.chosen_eddy.track_index};
                            end
                            
                            hdls.chosen_eddy.eddy_index = curr_track(find(curr_track(:, 3) == hdls.currentDateIndex, 1), 4);
                        end
                    else
                        hdls.chosen_eddy.eddy_index = [];
                    end
                end
                
                % Displaying eddy's information
                if ~isempty(hdls.chosen_eddy.eddy_index)
                    [eddy_lat, eddy_lon] = hdls.display_eddy_info(hdls.currentDateIndex, hdls.chosen_eddy.eddy_index, hdls.chosen_eddy.type);
                    if hdls.is_auto_zooming
                        hdls.zoom_in(eddy_lat, eddy_lon);
                    end
                end
            end
            
            hdls.is_any_eddy_selected = false;
            
        end
        
        function [eddy_lat, eddy_lon] = display_eddy_info(hdls, date_index, eddy_index, eddy_type)
            % Display the selected eddy info in the viewer
            text = 'Eddy info: \n';
            if strcmp(eddy_type, 'cyc') || strcmp(eddy_type, 'cyclonic')
                eddy_initial = 'cyc_';
            else
                eddy_initial = 'ant_';
            end
            
            for i = 1:length(hdls.displaying_eddy_attribute_names)
                curr_attribute_value = ...
                    hdls.eddy_attribute_data.([eddy_initial hdls.displaying_eddy_attribute_names{i}]){date_index}(eddy_index);
                curr_readable_name = hdls.displaying_eddy_attribute_readable_names{i};
                text = [text curr_readable_name ': ' num2str(curr_attribute_value) '\n'];
            end
            
            eddy_lat = hdls.eddy_attribute_data.([eddy_initial 'lats']){date_index}(eddy_index);
            eddy_lon = hdls.eddy_attribute_data.([eddy_initial 'lons']){date_index}(eddy_index);
            hdls.chosen_eddy.eddy_plot = geoshow(eddy_lat, eddy_lon, 'Marker', 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
            
            set(hdls.eddyInfoText, 'String', sprintf(text));
            
        end
        
        function track_index = get_eddy_track_index(hdls, date_index, eddy_index, eddy_type)
            % Get track index of an eddy
            if strcmp(eddy_type, 'cyc')
                curr_track_indexes = hdls.track_indexes.cyc_track_indexes;
            else
                curr_track_indexes = temp.track_indexes.ant_track_indexes;
            end
            
            track_index = curr_track_indexes{date_index}(eddy_index);
        end
        
        function clear_past_and_future_tracks(hdls)
            % Clear current past and future plots
            plot_field_names = {'cyc_other_eddy_plots', 'cyc_past_plots', 'cyc_future_plots', ...
                'ant_other_eddy_plots', 'ant_past_plots', 'ant_future_plots'};
            
            for plot_field_name = plot_field_names
                if ~isempty(hdls.(plot_field_name{1}))
                    for i = 1:length(hdls.(plot_field_name{1}))
                        delete(hdls.(plot_field_name{1})(i));
                    end
                end
            end
            
            % Clear chelton past and future plots
            if ~isempty(hdls.chelton_cyc_plots)
                plot_field_names = {'current_plot', 'past_plot', 'future_plot'};
                for plot_name = plot_field_names
                    if ~isempty(hdls.chelton_cyc_plots.(plot_name{1}))
                        delete(hdls.chelton_cyc_plots.(plot_name{1}));
                    end
                end
            end
            if ~isempty(hdls.chelton_ant_plots)
                plot_field_names = {'current_plot', 'past_plot', 'future_plot'};
                for plot_name = plot_field_names
                    if ~isempty(hdls.chelton_ant_plots.(plot_name{1}))
                        delete(hdls.chelton_ant_plots.(plot_name{1}));
                    end
                end
            end
            
        end
        
        function add_attribute_filter(hdls, attribute_name)
            % Add an attribute filter, also add it to eddy attribute data if needed
            if ~isfield(hdls.eddy_filters, attribute_name)
                hdls.eddy_filters.(attribute_name).min_value = -inf;
                hdls.eddy_filters.(attribute_name).max_value = inf;
            end
            
            % Check if this attribute is loaded, if not then load it
            if ~isfield(hdls.eddy_attribute_data, ['cyc_' attribute_name])
                temp = load([hdls.attribute_dir 'cyc_' attribute_name]);
                hdls.eddy_attribute_data.(['cyc_' attribute_name]) = temp.(['cyc_' attribute_name]);
            end
            if ~isfield(hdls.eddy_attribute_data, ['ant_' attribute_name])
                temp = load([hdls.attribute_dir 'ant_' attribute_name]);
                hdls.eddy_attribute_data.(['ant_' attribute_name]) = temp.(['ant_' attribute_name]);
            end
        end
        
        function set_attribute_filter_min_value(hdls, name, value)
            % Set minimum value of the corresponding attribute in eddy filters
            hdls.eddy_filters.(name).min_value = value;
        end
        
        function set_attribute_filter_max_value(hdls, name, value)
            % Set maximum value of the corresponding attribute in eddy filters
            hdls.eddy_filters.(name).max_value = value;
        end
        
        function add_displaying_attribute(hdls, readable_name, attribute_name)
            % load data into hdls.eddy_attribute_data if it is not existed
            if ~isfield(hdls.eddy_attribute_data, ['cyc_' attribute_name])
                temp = load([hdls.attribute_dir 'cyc_' attribute_name]);
                hdls.eddy_attribute_data.(['cyc_' attribute_name]) = temp.(['cyc_' attribute_name]);
            end
            if ~isfield(hdls.eddy_attribute_data, ['ant_' attribute_name])
                temp = load([hdls.attribute_dir 'ant_' attribute_name]);
                hdls.eddy_attribute_data.(['ant_' attribute_name]) = temp.(['ant_' attribute_name]);
            end
            
            hdls.displaying_eddy_attribute_names{end + 1} = attribute_name;
            hdls.displaying_eddy_attribute_readable_names{end + 1} = readable_name;
        end
        
        function update_date_text_box(hdls)
            % Get current date from date list box and display it in the date text box
            curr_date = hdls.dates(hdls.currentDateIndex);
            day = mod(curr_date, 100);
            month = (mod(curr_date, 10000) - day) / 100;
            year = (curr_date - month * 100 - day) / 10000;
            set(hdls.dateTextBox, 'String', datestr([year month day 0 0 0]));
        end
    end
    
end

