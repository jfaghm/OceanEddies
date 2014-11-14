function [tracks, revived, dropped_criteria, dropped_vicinity] = tolerance_track_lnn( eddies_path, type, time_frequency, tolerance, minimumArea ) % old args: eddies, time_frequency, tolerance
%TOLERANCE_TRACK_LNN Tracking eddies by lnn method with loss tolerance

%   ---- NOTE ----: This is not the regular version of track_lnn. This
%   version of track_lnn will interpolate fake eddies in-between two close
%   tracks. Our theory is that these nearby tracks are the same eddy, but
%   the eddy on the missing day just wasn't strong enough to be picked up
%   by the original track_lnn. We created this function to try to recover
%   some of the dropped eddies so that we could connect the broken tracks.

%   For each eddy in a timestep, all eddies in next timestep within a boundary are checked to see if there's an eddy
%   that qualifies some conditions to be stitched to current eddy. The north, south and east bounds are the gate
%   distance while the west bound is computed based on rossby-phase_speed.
% Input:
%   eddies_path: The path to the directory where eddies that were detected
%                by eddyscan were saved
%   type: Cyclone type of eddies ('anticyclonic' or 'cyclonic')
%   time_frequency: Number of days between timesteps. For weekly data, put
%                   7, for daily data, put 1
%   tolerance: Number of timesteps an eddy can be lost for
%   minimumArea: Minimum area of the eddies we want to include in the
%                tracking. I.E. eddy size is 4+, but we only want to
%                include eddies of size 9+ in the tracks. Set minimumArea
%                to 9


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
revived = 0;
dropped_criteria = 0;
dropped_vicinity = 0;

eddies_names = get_eddies_names(eddies_path, type);
eddy_length = length(eddies_names);
fake_eddy_count = ones(eddy_length, 1);
eddies = cell(eddy_length, 1);
indices = cell(eddy_length, 1);
orig_count = zeros(eddy_length, 1);
[eddies, indices, orig_count] = load_eddies_cell(eddies, indices, orig_count, eddies_names, minimumArea);

%% Begin tracking
tracks = {};

curr_track_indexes = nan(length(eddies{1}), 1); % track index of first eddies

for curr_time_step = 1:(length(eddies) - 1)
    curr_eddies_coordinates = [[eddies{curr_time_step}.Lat]' [eddies{curr_time_step}.Lon]'];
    next_eddies_coordinates = [[eddies{curr_time_step + 1}.Lat]' [eddies{curr_time_step + 1}.Lon]'];
    orig_next_eddies_coordinates_length = size(next_eddies_coordinates, 1);
    
    curr_real_indices = indices{curr_time_step};
    next_real_indices = indices{curr_time_step + 1};
    % eddy entries for connecting tracks.
    
    disp(curr_time_step)
    
    % The availability of next eddies, will be updated when an in-ranged eddy matches current eddy and the tracks are updated
    next_eddies_availabilities = true(size(next_eddies_coordinates, 1), 1);
    % Index of the tracks of the tracked next eddies, NaN for untracked eddies
    next_eddies_track_indexes = NaN(size(next_eddies_coordinates, 1), 1);
    
    % First, pad the next eddies so that euclidean distances don't mess up eddy distances at the edge of world map
    [padding_eddy_index, padding_eddies] = pad_eddies(next_eddies_coordinates, pad_range);
    padded_next_eddies = [next_eddies_coordinates; padding_eddies];
    
    padding_eddies_length = size(padding_eddies, 1);
    
    % Get in-ranged next eddies
    [next_padded_eddy_in_range_indexes, ~] = ...
        rangesearch(padded_next_eddies(:, 1:2), curr_eddies_coordinates(:, 1:2), rangesearch_radius);
    
    %next_padded_eddy_in_range_indexes =
    
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
        eddies_within_range = 0;
        matched = false;
        
        if curr_eddy_index <= length(curr_real_indices)
            curr_real_index = curr_real_indices(curr_eddy_index);
        else
            curr_real_index = orig_count(curr_time_step) + (curr_eddy_index - length(curr_real_indices));
        end
        
        for next_padded_eddy_index = next_padded_eddy_in_range_indexes{curr_eddy_index}
            % Get real next eddy index
            if next_padded_eddy_index > orig_next_eddies_coordinates_length && next_padded_eddy_index < orig_next_eddies_coordinates_length + ...
                    padding_eddies_length + 1
                % This is index of a padded eddy
                next_eddy_index = padding_eddy_index(next_padded_eddy_index - orig_next_eddies_coordinates_length);
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
                
                next_real_index = next_real_indices(next_eddy_index);
                
                if ~is_within_range(curr_eddy_lat, curr_eddy_lon, next_eddy_lat, next_eddy_lon, ...
                        dists(curr_distance_index), westbounds(curr_eddy_index), gate_distance, gate_distance_in_degree)
                    continue;
                else
                    eddies_within_range = eddies_within_range + 1;
                end
                
                if is_matched(eddies{curr_time_step}(curr_eddy_index), eddies{curr_time_step + 1}(next_eddy_index));
                    
                    % Update tracks and get out of the loop
                    if isnan(curr_track_indexes(curr_eddy_index))
                        % new track
                        track_id = length(tracks) + 1;
                        tracks{track_id}(1, :) = ...
                            [curr_eddy_lat curr_eddy_lon curr_time_step curr_real_index];
                        tracks{track_id}(2, :) = ...
                            [next_eddy_lat next_eddy_lon (curr_time_step + 1) next_real_index];
                    else
                        % old track
                        track_id = curr_track_indexes(curr_eddy_index);
                        %check if track is flagged
                        if length(tracks{track_id}(end,:)) == 5
                            if tracks{track_id}(end,5) ~= 0
                                revived = revived + 1;
                                %need to interpolate new locations for flagged
                                %track entries
                                for i = 1:size((tracks{track_id}), 1)
                                    if tracks{track_id}(i,5) ~= 0
                                        flag = tracks{track_id}(i,5);
                                        break
                                    end
                                end
                                
                                number_of_flags_at_end = 0;
                                for j = size(tracks{track_id},1):1
                                    if tracks{track_id}(j,5) ~= 0
                                        number_of_flags_at_end = number_of_flags_at_end + 1;
                                    else
                                        break;
                                    end
                                end
                                
                                last_real_track_index = size(tracks{track_id},1) - number_of_flags_at_end;
                                
                                lat_increment = (next_eddy_lat - tracks{track_id}(last_real_track_index, 1))/(number_of_flags_at_end + 1);
                                lon_increment = (next_eddy_lon - tracks{track_id}(last_real_track_index, 2))/(number_of_flags_at_end + 1);
                                %now just increment the flagged tracks' lat and lon by these amounts
                                for k = last_real_track_index + 1: size(tracks{track_id},1)
                                    tracks{track_id}(k,1) = tracks{track_id}(last_real_track_index,1) + (k - last_real_track_index)*lat_increment;
                                    tracks{track_id}(k,2) = tracks{track_id}(last_real_track_index,2) + (k - last_real_track_index)*lon_increment;
                                end
                            end
                            tracks{track_id}(end + 1, :) = ...
                                [next_eddy_lat next_eddy_lon (curr_time_step + 1) next_real_index 0 ];
                        else
                            tracks{track_id}(end + 1, :) = ...
                                [next_eddy_lat next_eddy_lon (curr_time_step + 1) next_real_index];
                        end
                    end
                    next_eddies_track_indexes(next_eddy_index) = track_id;
                    next_eddies_availabilities(next_eddy_index) = false;
                    matched = true;
                    break;
                end
                % getting here means that it had at least one eddy within
                % range but it wasn't a match for criteria
                
            end
            
            curr_distance_index = curr_distance_index + 1;
            
        end
        
        if ~matched
            if ~isnan(curr_track_indexes(curr_eddy_index))
                % getting here means there were no matches
                if ~eddies_within_range
                    dropped_vicinity = dropped_vicinity + 1;
                else
                    %there was at least one within range but none were matches
                    dropped_criteria = dropped_criteria + 1;
                end
            end
            
            if tolerance > 0
                %if a track already exists, add flag for potential
                %missing track.
                %This section checks if it has the max tolerated
                %number of flagged tracks already
                if ~isnan(curr_track_indexes(curr_eddy_index))
                    track_id = curr_track_indexes(curr_eddy_index);
                    
                    if length(tracks{track_id}(end,:)) == 5  % protect against out of bounds indexing (too large)
                        if size(tracks{track_id}, 1) > tolerance %protect against negative indexing
                            if tracks{track_id}(end - tolerance + 1, 5) ~= 0
                                %remove flagged tracks
                                
                                tracks{track_id} = tracks{track_id}(1: (end - tolerance),:);
                                continue;
                            end
                        end
                    else
                        %track isn't flagged at all, so add 5th column in order to add flags
                        tracks{track_id}(:,5) = 0;
                    end
                    %won't get here if it got trimmed due to the
                    %continue statement above
                    %now make entry to next coordinates and eddies arrays so we can
                    %search from this fake eddy in next timestep
                    lat_increment = tracks{track_id}(end, 1) - tracks{track_id}(end - 1, 1);
                    lon_increment = tracks{track_id}(end, 2) - tracks{track_id}(end - 1, 2);
                    next_eddies_coordinates(end+1,:) = [curr_eddies_coordinates(curr_eddy_index, 1) + lat_increment ...
                        curr_eddies_coordinates(curr_eddy_index, 2) + lon_increment];
                    %now add the stats of the current eddy to the
                    %end of the next time steps eddies, but alter
                    %the coordinates
                    eddies{curr_time_step + 1}(end+1) = eddies{curr_time_step}(curr_eddy_index);
                    eddies{curr_time_step + 1}(end).Lat = curr_eddies_coordinates(curr_eddy_index,1) + lat_increment;%next_eddies_coordinates(end,1);
                    eddies{curr_time_step + 1}(end).Lon = curr_eddies_coordinates(curr_eddy_index,2) + lon_increment;%next_eddies_coordinates(end,2);
                    %make a flagged track entry with the above interpolated stats
                    if ~eddies_within_range
                        flag = -1; %dropped for vicinity
                    else
                        flag = 1; % dropped for criteria
                    end
                    next_size = orig_count(curr_time_step + 1) + fake_eddy_count(curr_time_step + 1);
                    fake_eddy_count(curr_time_step + 1) = fake_eddy_count(curr_time_step + 1) + 1;
                    tracks{track_id}(end + 1, :) = ...
                        [next_eddies_coordinates(end, 1) next_eddies_coordinates(end, 2)...
                        (curr_time_step + 1) next_size flag];
                    next_eddies_track_indexes(length(eddies{curr_time_step + 1})) = track_id;
                    next_eddies_availabilities(size(next_eddies_coordinates), 1) = false;
                end
            end
            
        end
    end
    curr_track_indexes = next_eddies_track_indexes;
    eddies{curr_time_step} = [];
    [eddies, indices, orig_count] = load_eddies_cell(eddies, indices, orig_count, eddies_names, minimumArea);
end

for i = 1:length(tracks)
    track = tracks{i};
    [~,b] = size(track);
    if b < 5
        track(:, 5) = 0;
        tracks{i} = track;
    end
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
%if isempty(curr_amplitude) | isempty(next_amplitude) | isempty
%end
matched_amp = curr_amplitude > .25* next_amplitude && curr_amplitude < 2.75 * next_amplitude;
matched_area = curr_surface_area > .25 * next_surface_area && curr_surface_area < 2.75 * next_surface_area;

% matched = curr_amplitude > 0.25 * next_amplitude && curr_amplitude < 2.75 * next_amplitude ...
%     && curr_surface_area > 0.25 * next_surface_area && curr_surface_area < 2.75 * next_surface_area;
matched = matched_amp && matched_area;
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

function [modified_eddies_cell, modified_indices_cell, modified_orig_count_array] = load_eddies_cell(eddies_cell, real_indices_cell, orig_count_array, eddies_names, minimumArea)
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
    if strfind(eddy_name, 'anticyc')
        eddies = vars.ant_eddies;
        [f_eddies, real_indices, orig_count] = filter_eddies(eddies, minimumArea);
        eddies_cell{i} = f_eddies;
        real_indices_cell{i} = real_indices;
        orig_count_array(i) = orig_count;
    else
        eddies = vars.cyc_eddies;
        [f_eddies, real_indices, orig_count] = filter_eddies(eddies, minimumArea);
        eddies_cell{i} = f_eddies;
        real_indices_cell{i} = real_indices;
        orig_count_array(i) = orig_count;
    end
end
modified_eddies_cell = eddies_cell;
modified_indices_cell = real_indices_cell;
modified_orig_count_array = orig_count_array;
end

function [filtered_eddies, real_indices, original_eddy_count] = filter_eddies(eddies, minimumArea)
stats = [eddies.Stats];
areas = [stats.Area];
x = 1;
original_eddy_count = length(eddies);
for i = 1:length(eddies)
    if areas(i) >= minimumArea
        filtered_eddies(x) = eddies(i);
        real_indices(x) = i;
        x = x + 1;
    end
end
end