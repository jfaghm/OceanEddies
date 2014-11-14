function prepare_eddy_data_for_viewer( viewer_data_save_dir, dates, eddy_dir, ...
    cyclonic_tracks, anticyclonic_tracks, ssh_dir)
%PREPARE_EDDY_DATA_FOR_VIEWER Prepare data for the viewer
% Input:
%   viewer_data_save_dir: where to save data for track viewer
%   dates: 1D array of dates for data
%   eddy_dir: directory where you save eddy from eddyscan
%   cyclonic_tracks: tracks for cyclonic eddies
%   anticyclonic_tracks: tracks for anticyclonic eddies
%   ssh_dir: directory where you save ssh data slices
addpath('/project/expeditions/alindell/FullEddyViewer/data_code/');
%% Prepare directory for saving
if ~exist(viewer_data_save_dir, 'dir')
    mkdir(viewer_data_save_dir);
end

pixel_save_dir = [viewer_data_save_dir 'pixel_data/'];
if ~exist(pixel_save_dir, 'dir')
    mkdir(pixel_save_dir);
end

disp('saving pixel data');
load([ssh_dir 'lat.mat']);
load([ssh_dir 'lon.mat']);
save([pixel_save_dir 'lat.mat'], 'lat');
save([pixel_save_dir 'lon.mat'], 'lon');

%% Cyclonic attributes
disp('getting eddies attributes, will take a long time (about 30mins for 900 time slices)');

 if ~isempty(cyclonic_tracks)
     [ cyc_amps, cyc_geospeeds, cyc_lats, cyc_lons, cyc_pxcounts, cyc_pixels, cyc_surface_areas ] = ...
         get_eddy_attributes(eddy_dir, 'cyclonic', dates);

    cyc_types = cell(size(dates));
    for i = 1:length(dates)
        cyc_types{i} = zeros(size(cyc_lats{i}));
    end
    for i = 1:length(cyclonic_tracks)
        for j = 1:size(cyclonic_tracks{i},1)
            if length(cyclonic_tracks{i}(1,:)) == 5
                if cyclonic_tracks{i}(j,5) ~= 0
                    flagged_eddy_timestep = cyclonic_tracks{i}(j,3);
                    flagged_eddy_index = cyclonic_tracks{i}(j,4);
                    cyc_types{flagged_eddy_timestep}(flagged_eddy_index) = cyclonic_tracks{i}(j,5);
                end
            end
        end
    end
    
    cyclonic_tags = make_track_tags(cyclonic_tracks, cyc_types);
    save([viewer_data_save_dir 'cyclonic_tags.mat'], 'cyclonic_tags');

    cyc_eddy_counts = zeros(length(cyc_lats), 1);
    for i = 1:length(cyc_lats)
        cyc_eddy_counts(i) = length(cyc_lats{i});
    end

    cyc_lifetimes = get_eddy_lifetimes(cyc_eddy_counts, cyclonic_tracks);
    cyc_eddy_track_indexes = get_eddy_track_index(cyc_eddy_counts, cyclonic_tracks);

    attribute_to_save = {'amps', 'geospeeds', 'lats', 'lons', 'pxcounts', 'surface_areas', 'lifetimes', 'eddy_track_indexes', 'types'};
    disp('saving cyclonic attributes')
    for i = 1:length(attribute_to_save)
        curr_attribute = attribute_to_save{i};
        save([viewer_data_save_dir 'cyc_' curr_attribute '.mat'], ['cyc_' curr_attribute]);
    end

    if ~exist([pixel_save_dir 'cyclonic/'], 'dir')
        mkdir([pixel_save_dir 'cyclonic/']);
    end

    disp('saving cyclonic pixels')
    for i = 1:length(dates)
        data = cyc_pixels{i};
        save([pixel_save_dir 'cyclonic/pixels_' num2str(dates(i)) '.mat'], 'data');
    end
end

%% Anticyclonic attributes
if ~isempty(anticyclonic_tracks)
    [ ant_amps, ant_geospeeds, ant_lats, ant_lons, ant_pxcounts, ant_pixels, ant_surface_areas ] = ...
        get_eddy_attributes(eddy_dir, 'anticyc', dates);

    ant_types = cell(size(dates));
    for i = 1:length(dates)
        ant_types{i} = zeros(size(ant_lats{i}));
    end
    for i = 1:length(anticyclonic_tracks)
        for j = 1:size(anticyclonic_tracks{i},1)
            if length(anticyclonic_tracks{i}(1,:)) == 5
                if anticyclonic_tracks{i}(j,5) ~= 0
                    flagged_eddy_timestep = anticyclonic_tracks{i}(j,3);
                    flagged_eddy_index = anticyclonic_tracks{i}(j,4);
                    ant_types{flagged_eddy_timestep}(flagged_eddy_index) = anticyclonic_tracks{i}(j,5);
                end
            end
        end
    end

    anticyclonic_tags = make_track_tags(anticyclonic_tracks, ant_types);
    save([viewer_data_save_dir 'anticyclonic_tags.mat'], 'anticyclonic_tags');

    ant_eddy_counts = zeros(length(ant_lats), 1);
    for i = 1:length(ant_lats)
        ant_eddy_counts(i) = length(ant_lats{i});
    end

    ant_lifetimes = get_eddy_lifetimes(ant_eddy_counts, anticyclonic_tracks);
    ant_eddy_track_indexes = get_eddy_track_index(ant_eddy_counts, anticyclonic_tracks);

    attribute_to_save = {'amps', 'geospeeds', 'lats', 'lons', 'pxcounts', 'surface_areas', 'lifetimes', 'eddy_track_indexes', 'types'};
    for i = 1:length(attribute_to_save)
        curr_attribute = attribute_to_save{i};
        save([viewer_data_save_dir 'ant_' curr_attribute '.mat'], ['ant_' curr_attribute]);
    end

    if ~exist([pixel_save_dir 'anticyclonic/'], 'dir')
        mkdir([pixel_save_dir 'anticyclonic/']);
    end

    for i = 1:length(dates)
        data = ant_pixels{i};        
        save([pixel_save_dir 'anticyclonic/pixels_' num2str(dates(i)) '.mat'], 'data');
    end
end

end
