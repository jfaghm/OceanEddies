function complete_run(ssh_path, eddies_save_path, tracks_save_path, fake_eddies, viewer_data_save_path, viewer_path, varargin)
% NOTE: Please provide full path names for all paths.
%
% The purpose of this function is to automate the entire gauntlet of
% running all of the code to go from having only MATLAB SSH data to getting
% the data set up to be viewed on the tracks viewer. This function should
% automate the following steps:
% 1. Scan SSH data for eddies
% 2. Save detected eddies
% 3. Build LNN tracks for these eddies (Possibly with fake eddies, if the
%    user of the script wants fake eddies)
% 4. Format and process saved data so that it can be viewed in Hung's
%    viewer that we include
%
% NOTE: The process of turning NetCDF file data into MATLAB data is not
% accomplished in this function.
% The function set_up_ssh_data is provided that will accomplish this for
% the user, but the user will have to provide the variable names that match
% the function inputs. Refer to the comments at the top of the function
% set_up_ssh_data for a description of what each of the required variables are.
%
% This script will not open the viewer for the user.
% To open the viewer, run the start_track_viewer script inside the
% tracks_viewer directory.

p = inputParser;
defaultLat = NaN;
defaultLon = NaN;
defaultDates = NaN;
defaultAreaMap = NaN;
defaultScanType = 'v2';
defaultMinPixelSize = 9;
defaultThresholdStep = 0.05;
defaultSSHUnits = 'centimeters';
defaultPaddingFlag = true;

addRequired(p, 'ssh_dir');
addRequired(p, 'eddies_save_path');
addRequired(p, 'fake_eddies');

addParameter(p, 'lat', defaultLat);
addParameter(p, 'lon', defaultLon);
addParameter(p, 'dates', defaultDates);
addParameter(p, 'area_map', defaultAreaMap);
addParameter(p, 'scan_type', defaultScanType);
addParameter(p, 'minimumArea', defaultMinPixelSize, @isnumeric);
addParameter(p, 'thresholdStep', defaultThresholdStep, @isnumeric);
addParameter(p, 'isPadding', defaultPaddingFlag);
addParameter(p, 'sshUnits', defaultSSHUnits);

parse(p, ssh_path, eddies_save_path, fake_eddies, varargin{:});

lat = p.Results.lat;
lon = p.Results.lon;
dates = p.Results.dates;
area_map = p.Results.area_map;
scan_type = p.Results.scan_type;
minimumArea = p.Results.minimumArea;
thresholdStep = p.Results.thresholdStep;
isPadding = p.Results.isPadding;
SSH_Units = p.Results.sshUnits;
if ~strcmp(ssh_path(end), '/')
    ssh_path = strcat(ssh_path, '/');
end
if ~strcmp(eddies_save_path(end), '/')
    eddies_save_path = strcat(eddies_save_path, '/');
end
if ~strcmp(tracks_save_path(end), '/')
    tracks_save_path = strcat(tracks_save_path, '/');
end
if ~strcmp(viewer_data_save_path(end), '/')
    viewer_data_save_path = strcat(viewer_data_save_path, '/');
end
ssh_names = get_ssh_names(ssh_path);
if isnan(lat)
    vars = load([ssh_path, 'lat.mat']);
    names = fieldnames(vars);
    lat = vars.(names{1});
end
if isnan(lon)
    vars = load([ssh_path, 'lon.mat']);
    names = fieldnames(vars);
    lon = vars.(names{1});
end
if isnan(dates)
    vars = load([ssh_path, 'dates.mat']);
    names = fieldnames(vars);
    dates = vars.(names{1});
end
if isnan(area_map)
    vars = load([ssh_path, 'area_map.mat']);
    names = fieldnames(vars);
    area_map = vars.(names{1});
end
if ~exist(eddies_save_path, 'dir')
    mkdir(eddies_save_path);
end
old_path = cd('eddyscan/');
disp('Scanning SSH data for eddies');
for i = 1:length(ssh_names)
    disp(['Iteration ', num2str(i)]);
    vars = load(ssh_names{i});
    names = fieldnames(vars);
    ssh_data = vars.(names{1});
    ant_eddies = scan_single(ssh_data, lat, lon, dates(i), 'anticyc', scan_type, area_map, 'sshUnits', SSH_Units,...
                             'thresholdStep', thresholdStep, 'minimumArea', minimumArea, 'isPadding', isPadding);
    par_save([eddies_save_path, 'anticyc_', num2str(dates(i)), '.mat'], ant_eddies);
    cyc_eddies = scan_single(ssh_data, lat, lon, dates(i), 'cyclonic', scan_type, area_map, 'sshUnits', SSH_Units,...
                             'thresholdStep', thresholdStep, 'minimumArea', minimumArea, 'isPadding', isPadding);
    par_save([eddies_save_path, 'cyclonic_', num2str(dates(i)), '.mat'], cyc_eddies);
end
cd(old_path);
% Track eddies and save tracks
if ~exist(tracks_save_path, 'dir')
    mkdir(tracks_save_path);
end
if ~exist(viewer_data_save_path, 'dir')
    mkdir(viewer_data_save_path);
end
old_path = cd('track_lnn/');
disp('Tracking eddies');
if strcmp(fake_eddies, 'yes')
    anticyclonic_tracks = tolerance_track_lnn(eddies_save_path, 'anticyc', 1, 1, minimumArea);
    cyclonic_tracks = tolerance_track_lnn(eddies_save_path, 'cyclonic', 1, 1, minimumArea);
    modified_eddies_path = [viewer_data_save_path, 'modified_eddies/'];
    modified_tracks_path = [viewer_data_save_path, 'modified_tracks/'];
    if ~exist(modified_eddies_path, 'dir')
        mkdir(modified_eddies_path);
    end
    if ~exist(modified_tracks_path, 'dir')
        mkdir(modified_tracks_path);
    end
    disp('Modifying eddy data to include fake eddies (for the sake of the tracks)');
    process_eddies_and_tracks_tolerance('anticyc', dates, eddies_save_path, anticyclonic_tracks, modified_eddies_path, modified_tracks_path);
    process_eddies_and_tracks_tolerance('cyclonic', dates, eddies_save_path, cyclonic_tracks, modified_eddies_path, modified_tracks_path);
    vars = load([modified_tracks_path, 'anticyc_tracks_processed.mat']);
    s = fieldnames(vars);
    anticyclonic_tracks = vars.(s{1});
    vars = load([modified_tracks_path, 'cyclonic_tracks_processed.mat']);
    s = fieldnames(vars);
    cyclonic_tracks = vars.(s{1});
    eddies_save_path = modified_eddies_path;
else
    anticyclonic_tracks = track_lnn(eddies_save_path, 'anticyc', 1); % Possibly change this so it can be an optional argument in input parser
    cyclonic_tracks = track_lnn(eddies_save_path, 'cyclonic', 1); % Same as above
end
save([tracks_save_path, 'anticyclonic_tracks.mat'], 'anticyclonic_tracks');
save([tracks_save_path, 'cyclonic_tracks.mat'], 'cyclonic_tracks');
eddies_t = reformat_track_data_to_chelton(eddies_save_path, dates, anticyclonic_tracks, cyclonic_tracks);%#ok
save([tracks_save_path, 'chelton_structured_tracks.mat'], 'eddies_t');
% Set up data for viewer
disp('Preparing data for viewer');
prepare_eddy_data_for_viewer(viewer_data_save_path, dates, eddies_save_path, cyclonic_tracks, anticyclonic_tracks, ssh_path);
cd(old_path);
% Deleting old viewer files
files = dir([viewer_path, 'SSH/']);
old_path = cd([viewer_path, 'SSH/']);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        if files(i).isdir
            rmdir(file, 's');
        else
            delete(file);
        end
    end
end
files = dir([viewer_path, 'track_data/']);
cd([viewer_path, 'track_data/']);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        if files(i).isdir
            rmdir(file, 's');
        else
            delete(file);
        end
    end
end
files = dir([viewer_path, 'attributes/']);
cd([viewer_path, 'attributes/']);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        if files(i).isdir
            rmdir(file, 's');
        else
            delete(file);
        end
    end
end
files = dir([viewer_path, 'pixels_data/']);
cd([viewer_path, 'pixels_data/']);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        if files(i).isdir
            rmdir(file, 's');
        else
            delete(file);
        end
    end
end
cd(old_path);
% Copying new viewer files into place
files = dir(ssh_path);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        copyfile([ssh_path, file], [viewer_path, 'SSH/', file]);
    end
end
files = dir(tracks_save_path);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        copyfile([tracks_save_path, file], [viewer_path, 'track_data/', file]);
    end
end
files = dir(viewer_data_save_path);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        if ~files(i).isdir
            if strcmp(file, 'anticyclonic_tags.mat') || strcmp(file, 'cyclonic_tags.mat')
                copyfile([viewer_data_save_path, file], [viewer_path, 'track_data/', file]);
            else
                copyfile([viewer_data_save_path, file], [viewer_path, 'attributes/', file]); 
            end
        end
    end
end
files = dir([viewer_data_save_path, 'pixel_data/']);
for i = 1:length(files)
    file = files(i).name;
    if ~strcmp(file, '.') && ~strcmp(file, '..')
        copyfile([viewer_data_save_path, 'pixel_data/', file], [viewer_path, 'pixels_data/', file]);
    end
end 

end

function par_save(path, eddies)%#ok
save(path, 'eddies');
end

function [ssh_names] = get_ssh_names(path)
% path is the path to the eddies directory
% type is anticyclonic or cyclonic
if ~strcmp(path(end), '/')
    path = strcat(path, '/');
end
files = dir(path);
x = 0;
for i = 1:length(files)
    if ~isempty(strfind(files(i).name, 'ssh_'))
        x = x + 1;
    end
end
ssh_names = cell(x, 1);
x = 1;
for i = 1:length(files)
    if files(i).isdir && ~isequal(files(i).name, '.') && ~isequal(files(i).name, '..')
        rec_names = get_ssh_names([path, files(i).name, '/']);
        for j = 1:length(rec_names)
            ssh_names{x} = rec_names{j};
            x = x + 1;
        end
        continue;
    end
    file = files(i).name;
    [~, name, ext] = fileparts([path, file]);
    if ~isempty(strfind(name, 'ssh_')) && strcmp(ext, '.mat')
        ssh_names{x} = [path, file];
        x = x + 1;
    end
end
end