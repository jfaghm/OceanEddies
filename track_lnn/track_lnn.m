function [ tracks ] = track_lnn( eddies_path, type, time_frequency )
%TRACK_LNN Tracking eddies by lnn method
%   For each eddy in a timestep, all eddies in next timestep within a boundary are checked to see if there's an eddy
%   that qualifies some conditions to be stitched to current eddy. The north, south and east bounds are the gate
%   distance while the west boudn is computed based on rossby-phase_speed.
% Input:
%   eddies: cell array of eddies resulting from eddyscan
%   times_frequency: number of days between 2 timesteps
%
% Understanding the columns of the tracks
% Column 1 is the latitude of the centroid of the eddy
% Column 2 is the longitude of the centroid of the eddy
% Column 3 is the time slice (day) that the eddy is from. To use this data to
% get the actual day that the eddy is from, use this value as an index to a
% dates array, and the return value of your dates array will be the day the
% eddy is from.
% Column 4 is the index in the struct array of eddies for that particular
% day. If you get the correct eddies struct that corresponds to the date in
% column 3, the value in this column is the index in that struct where this
% actual eddy resides. It is through getting the appropriate struct and
% accessing the appropriate entry that we relate this track data to actual
% eddies in the struct.

%% Setting constants
temp = load('rossby_daily_phase_speeds.mat');
rossby_phase_speed = temp.rossby_daily_phase_speeds;
rossby_phase_speed(:, 3) = rossby_phase_speed(:, 3) * time_frequency;

gate_distance = 150/7 * time_frequency; % 150km is default maximum travel distance for 1 week
gate_distance_in_degree = km2deg(gate_distance);

% Make lat and lon to be in [-180 180]
rossby_phase_speed(rossby_phase_speed(:, 2) > 180, 2) = rossby_phase_speed(rossby_phase_speed(:, 2) > 180, 2) - 360;
rossby_phase_speed(rossby_phase_speed(:, 2) < -180, 2) = rossby_phase_speed(rossby_phase_speed(:, 2) < -180, 2) + 360;
max_rossby_lat = max(rossby_phase_speed(:, 1));
min_rossby_lat = min(rossby_phase_speed(:, 1));

rangesearch_radius = 5; % euclidean radius in degree for rangesearch

% All next eddies with longitude in range [min_lon (min_lon + pad_range)] and [(max_lon - pad_range) max_lon] will be
% duplicated with longitude lon+360 or lon-360 to make sure Euclidean distances can still get the eddies on the other
% side of the map
pad_range = 5; 

eddies_names = get_eddies_names(eddies_path, type);
eddy_length = length(eddies_names);
eddies = cell(eddy_length, 1);
eddies = load_eddies_cell(eddies, eddies_names);

%% Begin tracking
tracks = {};

curr_track_indexes = nan(length(eddies{1}), 1); % track index of first eddies

for curr_time_step = 1:(length(eddies) - 1)
    curr_eddies_coordinates = [[eddies{curr_time_step}.Lat]' [eddies{curr_time_step}.Lon]'];
    next_eddies_coordinates = [[eddies{curr_time_step + 1}.Lat]' [eddies{curr_time_step + 1}.Lon]'];
    
    % The availability of next eddies, will be updated when an in-ranged eddy matches current eddy and the tracks are updated
    next_eddies_availabilities = true(size(next_eddies_coordinates, 1), 1);
    % Index of the tracks of the tracked next eddies, NaN for untracked eddies
    next_eddies_track_indexes = NaN(size(next_eddies_coordinates, 1), 1);
    
    % First, pad the next eddies so that euclidean distances don't mess up eddy distances at the edge of world map
    [padding_eddy_index, padding_eddies] = pad_eddies(next_eddies_coordinates, pad_range);    
    padded_next_eddies = [next_eddies_coordinates; padding_eddies];

    % Get in-ranged next eddies
    [next_padded_eddy_in_range_indexes, ~] = ...
        rangesearch(padded_next_eddies(:, 1:2), curr_eddies_coordinates(:, 1:2), rangesearch_radius);
    
    % Get distances from current eddies to in-ranged next eddies
    [dists, first_curr_eddy_index_in_distance_data] = get_eddy_distances(curr_eddies_coordinates, padded_next_eddies, ...
        next_padded_eddy_in_range_indexes);

    % Get westbound of curr eddies
    westbounds = get_west_bounds(curr_eddies_coordinates(:, 1:2), gate_distance, rossby_phase_speed, ...
        max_rossby_lat, min_rossby_lat);
    
    % For each current eddy, check if any in-ranged next eddy matches and update tracks
    for curr_eddy_index = 1:size(curr_eddies_coordinates, 1)
        % Index of the distance between current eddy and next eddy in the dists array
        curr_distance_index = first_curr_eddy_index_in_distance_data(curr_eddy_index); 
        for next_padded_eddy_index = next_padded_eddy_in_range_indexes{curr_eddy_index}
            % Get real next eddy index
            if next_padded_eddy_index > size(next_eddies_coordinates, 1)
                % This is index of a padded eddy
                next_eddy_index = padding_eddy_index(next_padded_eddy_index - size(next_eddies_coordinates, 1));
            else
                next_eddy_index = next_padded_eddy_index;
            end
            
            % Check if the next eddy matches the current eddy
            if next_eddies_availabilities(next_eddy_index)
                % Only check available next eddies
                curr_eddy_lat = curr_eddies_coordinates(curr_eddy_index, 1);
                curr_eddy_lon = curr_eddies_coordinates(curr_eddy_index, 2);
                next_eddy_lat = next_eddies_coordinates(next_eddy_index, 1);
                next_eddy_lon = next_eddies_coordinates(next_eddy_index, 2);

                if ~is_within_range(curr_eddy_lat, curr_eddy_lon, next_eddy_lat, next_eddy_lon, ...
                        dists(curr_distance_index), westbounds(curr_eddy_index), gate_distance, gate_distance_in_degree)
                    continue;
                end
                    
                if is_matched(eddies{curr_time_step}(curr_eddy_index), eddies{curr_time_step + 1}(next_eddy_index))
                    % Update tracks and get out of the loop
                    if isnan(curr_track_indexes(curr_eddy_index))
                        % new track
                        track_id = length(tracks) + 1;
                        tracks{track_id}(1, :) = ...
                            [curr_eddy_lat curr_eddy_lon curr_time_step curr_eddy_index];
                        tracks{track_id}(2, :) = ...
                            [next_eddy_lat next_eddy_lon (curr_time_step + 1) next_eddy_index];
                    else
                        % old track
                        track_id = curr_track_indexes(curr_eddy_index);
                        tracks{track_id}(end + 1, :) = ...
                            [next_eddy_lat next_eddy_lon (curr_time_step + 1) next_eddy_index];
                    end
                    
                    next_eddies_track_indexes(next_eddy_index) = track_id;
                    next_eddies_availabilities(next_eddy_index) = false;
                    break;
                end
            end
            
            curr_distance_index = curr_distance_index + 1;
        end
    end
    
    curr_track_indexes = next_eddies_track_indexes;
    eddies{curr_time_step} = [];
    eddies = load_eddies_cell(eddies, eddies_names);
end

end

function within_range = is_within_range(curr_lat, curr_lon, next_lat, next_lon, km_distance, westbound, ...
    gate_distance, gate_distance_in_degree)
% An approximate way of checking if the eddy in next timestep is within edddy in current timestep's range,
% following the description in D.B. Chelton et al. / Progress in Oceanography 91 (2011) page 208
% The north, east and south bounds are defined by the gate distance while the westbound is precomputed by rossby
% phase speed.
% Input:
%   curr_lat: latitude of the eddy in current timestep
%   curr_lon: longitude of the eddy in current timestep
%   next_lat: latitude of the eddy in next timestep
%   next_lon: longitude of the eddy in next timestep
%   km_distance: distance in km between the eddies in current and next timestep
%   gate_distance: default value of how far an eddy can travel in one timestep in km
%   gate_distance: default value of how far an eddy can travel in one timestep in degree

% Check north and south bound
if next_lat > curr_lat + gate_distance_in_degree || next_lat < curr_lat - gate_distance_in_degree
    within_range = false; % Avoid using km2deg or deg2km because 
else
    % Check east and west bound
    if abs(next_lon - curr_lon) > 180
        if next_lon > curr_lon
            curr_lon = curr_lon + 360;
        else
            next_lon = next_lon + 360;
        end
    end
    if next_lon >= curr_lon
        is_on_east_side = true;
    else
        is_on_east_side = false;
    end
    
    if is_on_east_side
        within_range = km_distance <= gate_distance;
    else
        within_range = km_distance <= westbound;
    end
    
end

end
    
function westbounds = get_west_bounds(eddy_coordinates, gate_distance, phase_speed_data, max_rossby_lat, min_rossby_lat)
% Getting westbound of eddies by eddy coordinates and rossby phasespeed data
% West bound of an eddy is defined as the maximum value between 1.75 * rossby_phase_speed and default gate_distance
%   eddy_coordinates: coordinates of eddies in format [lat lon]
%   gate_distance: the default maximum distance an eddy can travel in a single timestep
%   phase_speed_data: rossby phase speed data in format [lat lon speed]
%   max_rossby_lat: to make sure eddies with latitude out of range get the default gate distance
%   min_rossby_lat: to make sure eddies with latitude out of range get the default gate distance

    curr_eddy_lats = eddy_coordinates(:, 1);
    curr_eddy_lons = eddy_coordinates(:, 2);
    % Convert eddy longtidue format to -180 to 180 to make sure knn search work
    curr_eddy_lons(curr_eddy_lons > 180) = curr_eddy_lons(curr_eddy_lons > 180) - 360;
    curr_eddy_lons(curr_eddy_lons < -180) = curr_eddy_lons(curr_eddy_lons < -180) + 360;

	nearest_ind = knnsearch(phase_speed_data(:, 1:2), [curr_eddy_lats curr_eddy_lons]);
    westbounds = 1.75 * phase_speed_data(nearest_ind, 3);
    westbounds(westbounds < gate_distance) = gate_distance;
    % Make sure out of range eddies get the default value
    westbounds(curr_eddy_lats > max_rossby_lat | curr_eddy_lats < min_rossby_lat) = gate_distance;
    
end

function [dists, first_curr_eddy_index_in_distance_data] = get_eddy_distances(curr_eddies, next_eddies, ...
    next_eddies_indexes)
% Get distances from current eddies to next eddies with indexes in the cell array next_eddies_indexes. This function
% computes the distance in one distance and deg2km to increase the tracking function performance
% Also return an array of indexes of the first appearance of a curr eddy in the distance array
% Input:
%   curr_eddies: eddies in current timestep with format [lat lon ...]
%   next_eddies: eddies in next timestep with format [lat lon ...]
%   next_eddies_indexes: a cell array of indexes of next eddies that will be computed the distances to current eddies

next_eddy_indexes_lengths = cellfun('length', next_eddies_indexes);
vectorized_next_eddy_indexes = [next_eddies_indexes{:}]';
vectorized_curr_eddy_indexes = zeros(sum(next_eddy_indexes_lengths), 1);
curr_index = 1;
for i = 1:length(next_eddy_indexes_lengths)
    vectorized_curr_eddy_indexes(curr_index:(curr_index + next_eddy_indexes_lengths(i) - 1)) = i;
    curr_index = curr_index + next_eddy_indexes_lengths(i);
end

dists = deg2km(distance(curr_eddies(vectorized_curr_eddy_indexes, 1:2), ...
    next_eddies(vectorized_next_eddy_indexes, 1:2)));

first_curr_eddy_index_in_distance_data = ones(length(next_eddy_indexes_lengths), 1);
for i = 2:length(next_eddy_indexes_lengths)
    first_curr_eddy_index_in_distance_data(i) = first_curr_eddy_index_in_distance_data(i - 1) + next_eddy_indexes_lengths(i - 1);
end

end

function [padding_eddy_index, padding_eddies] = pad_eddies(eddies, pad_range)
% Duplicate eddies in range [min_lon (min_lon + pad_range)] and [(max_lon - pad_range) max_lon] to make sure knnsearch
% work correctly to get in-range eddies in next timestep
%   eddies: eddies in format [lat lon ...]
%   pad_range: how far we want to pad (in degree)

min_lon = min(eddies(:, 2));
max_lon = max(eddies(:, 2));
padding_eddy_index = find( (eddies(:, 2) >= min_lon & eddies(:, 2) <= (min_lon + pad_range)) ...
    | (eddies(:, 2) >= (max_lon - pad_range) & eddies(:, 2) <= max_lon ) );

padding_eddies = eddies(padding_eddy_index, :);
padding_eddies(padding_eddies(:, 2) <= (min_lon + pad_range), 2) = ...
    padding_eddies(padding_eddies(:, 2) <= (min_lon + pad_range), 2) + 360;
padding_eddies(padding_eddies(:, 2) >= (max_lon - pad_range), 2) = ...
    padding_eddies(padding_eddies(:, 2) >= (max_lon - pad_range), 2) - 360;
    
end

function matched = is_matched(curr_eddy, next_eddy)
% An eddy is consider matched with current eddy if the amplitude and surface area is in range [0.25 2.75] *
% curr_eddy_amp/surface_area
%   curr_eddy: an eddy in current timestep in format [lat lon amp surface_area]
%   next_eddy: an eddy in next timestep in format [lat lon amp surface_area]

curr_amplitude = curr_eddy.Amplitude;
next_amplitude = next_eddy.Amplitude;
curr_surface_area = curr_eddy.SurfaceArea;
next_surface_area = next_eddy.SurfaceArea;

matched = curr_amplitude > 0.25 * next_amplitude && curr_amplitude < 2.75 * next_amplitude ...
    && curr_surface_area > 0.25 * next_surface_area && curr_surface_area < 2.75 * next_surface_area;

end

function [eddies_names] = get_eddies_names(path, type)
% path is the path to the eddies directory
% type is anticyclonic or cyclonic
if ~strcmp(path(end), '/')
    path = strcat(path, '/');
end
files = dir(path);
x = 0;
for i = 1:length(files)
    if ~isempty(strfind(files(i).name, [type, '_']))
        x = x + 1;
    end
end
eddies_names = cell(x, 1);
x = 1;
for i = 1:length(files)
    if files(i).isdir && ~isequal(files(i).name, '.') && ~isequal(files(i).name, '..')
        rec_names = get_eddies_names([path, files(i).name, '/'], type);
        for j = 1:length(rec_names)
            eddies_names{x} = rec_names{j};
            x = x + 1;
        end
        continue;
    end
    file = files(i).name;
    [~, name, ext] = fileparts([path, file]);
    if ~isempty(strfind(name, [type, '_'])) && strcmp(ext, '.mat')
        eddies_names{x} = [path, file];
        x = x + 1;
    end
end
end

function [modified_eddies_cell] = load_eddies_cell(eddies_cell, eddies_names)
count_to_load = 10;
names_length = length(eddies_names);
x = 0;
pos_1 = 1;
for i = 1:length(eddies_cell)
    if ~isempty(eddies_cell{i})
        if x == 0
            pos_1 = i;
        end
        x = x + 1;
    end
end
iterations = count_to_load - x;
first_empty_pos = pos_1 + x;
last_empty_pos = first_empty_pos + iterations - 1;
if last_empty_pos > names_length
    last_empty_pos = names_length;
end
for i = first_empty_pos:last_empty_pos
    eddy_name = eddies_names{i};
    vars = load(eddy_name);
    names = fieldnames(vars);
    eddies_cell{i} = vars.(names{1});
end
modified_eddies_cell = eddies_cell;
end