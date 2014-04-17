%% Input variable
ssh_save_dir = 'SSH/';
pixel_save_dir = 'pixels_data/';
track_save_dir = 'track_data/';
attribute_dir = 'attributes/'; 
chelton_save_dir = 'chelton_data/';

% Loading cyclonic and anticyclonic tracks in lnn format
if ~exist('cyclonic_tracks', 'var')
    disp('loading tracks');
    temp = load([track_save_dir 'cyclonic_tracks.mat']);
    cyclonic_tracks = temp.cyclonic_tracks;
    temp = load([track_save_dir 'anticyclonic_tracks.mat']);
    anticyclonic_tracks = temp.anticyclonic_tracks;
end

%% Setting up parameter to start the viewer

% Loading dates
if ~exist('dates', 'var')
    temp = load([ssh_save_dir 'dates.mat']);
    dates = temp.dates;
end

if ~exist('track_data', 'var');
    disp('getting track data');
    track_data.cyc_tracks = cyclonic_tracks;
    track_data.ant_tracks = anticyclonic_tracks;
    tic
    temp = load([track_save_dir 'cyclonic_tags.mat']);
    track_data.cyc_tags = temp.cyclonic_tags;
    temp = load([track_save_dir 'anticyclonic_tags.mat']);
    track_data.ant_tags = temp.anticyclonic_tags;
    toc
end

if ~exist('background_data', 'var')
    background_data(1).name = 'SSH';
    background_data(1).dir = ssh_save_dir;
    background_data(1).file_initial = 'ssh';
    temp = load([ssh_save_dir 'lat.mat']);
    background_data(1).lat = temp.lat;
    temp = load([ssh_save_dir 'lon.mat']);
    background_data(1).lon = temp.lon;
end

if ~exist('track_indexes', 'var')
    disp('loading track indexes');
    temp = load([attribute_dir 'cyc_eddy_track_indexes.mat']);
    track_indexes.cyc_track_indexes = temp.cyc_eddy_track_indexes;
    temp = load([attribute_dir 'ant_eddy_track_indexes.mat']);
    track_indexes.ant_track_indexes = temp.ant_eddy_track_indexes;
end

if ~exist('eddy_attribute_data', 'var')
    disp('loading track attributes');
    attribute_names = {'lats', 'lons', 'types'};
    for i = 1:length(attribute_names)
        curr_name = attribute_names{i};
        temp = load([attribute_dir 'cyc_' curr_name '.mat']);
        eddy_attribute_data.(['cyc_' curr_name]) = temp.(['cyc_' curr_name]);
        temp = load([attribute_dir 'ant_' curr_name '.mat']);
        eddy_attribute_data.(['ant_' curr_name]) = temp.(['ant_' curr_name]);
    end
end

if ~exist('chelton_eddies', 'var');
    disp('loading chelton eddies');
    temp = load([chelton_save_dir 'chelton_cyc_cell_tracks']);
    chelton_eddies.cyc = temp.chelton_cyc_cell_tracks;
    temp = load([chelton_save_dir 'chelton_ant_cell_tracks']);
    chelton_eddies.ant = temp.chelton_ant_cell_tracks;
    temp = load([chelton_save_dir 'chelton_cyc_date_indexes.mat']);
    chelton_eddies.cyc_date_indexes = temp.chelton_cyc_date_indexes;
    temp = load([chelton_save_dir 'chelton_ant_date_indexes.mat']);
    chelton_eddies.ant_date_indexes = temp.chelton_ant_date_indexes;
end

% initialize eddy plot specification
eddy_plotting_data.eddy_types = 0;
eddy_plotting_data.eddy_markers{1} = 'S';
eddy_plotting_data.eddy_colors{1} = [0.5 0 0.5];
eddy_plotting_data.eddy_type_names{1} = 'Eddy';

%% Start viewer
[hdls] = tracks_viewer(dates, track_data, background_data, pixel_save_dir, ...
    track_indexes, eddy_attribute_data, attribute_dir, eddy_plotting_data, chelton_eddies);