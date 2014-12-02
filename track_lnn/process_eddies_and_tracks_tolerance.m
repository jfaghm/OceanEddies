function [eddies, tracks] = process_eddies_and_tracks_tolerance(type, dates, eddies_path, tracks, eddies_save_dir, tracks_save_dir)
% This function is for preparing eddy and track data for being shown in the
% eddy viewer. Simply run this function with the required parameters, then
% replace the data in the folders inside tracks_viewer with your own data.

%% function to load eddies.mat files, add flagged track eddies to the .mat
%%file, and then give that eddy all the required fields/properties with
%%values that are the average of the two eddies on either side of it. 
if ~strcmp(eddies_save_dir(end), '/')
    eddies_save_dir = strcat(eddies_save_dir, '/');
end
if ~strcmp(tracks_save_dir(end), '/')
    tracks_save_dir = strcat(tracks_save_dir, '/');
end
eddies_names = get_eddies_names(eddies_path, type);
eddy_length = length(eddies_names);
fake_eddy_count = ones(eddy_length, 1);
orig_eddy_count = zeros(eddy_length, 1);
eddies = cell(eddy_length, 1);
iterations_since_needed = zeros(eddy_length, 1);
has_been_loaded = false(eddy_length, 1);
max_iterations = round(length(tracks) / 10);

first_time_slice = num2str(dates(1));

if ~exist(eddies_save_dir, 'dir')
    mkdir(eddies_save_dir);
end

if isempty(tracks)
    error('Please provide a non-empty input for tracks');
end

%% now go through and add the flagged eddies to eddies_cells and alter eddy indices in tracks, and resave them

%disp('altering eddies and tracks')
for i = 1:length(tracks)           
    iterations_since_needed = iterations_since_needed + 1;
    if size(tracks{i},2) == 5
        for j = 1:size(tracks{i},1)            
            if tracks{i}(j,5) ~= 0
                eddy_before_index = tracks{i}(j-1, 4);                
                date_index = tracks{i}(j,3);
                iterations_since_needed(date_index - 1:date_index) = 0;
                has_been_loaded(date_index - 1:date_index) = true;
                serial_date = date_index + datenum(first_time_slice, 'yyyymmdd') - 1;
                date = datestr(serial_date, 'yyyymmdd');
                [eddies, orig_eddy_count] = fetch_eddies(eddies, eddies_names, date_index, orig_eddy_count, eddies_save_dir);
                [eddies, orig_eddy_count] = fetch_eddies(eddies, eddies_names, date_index - 1, orig_eddy_count, eddies_save_dir);
                fake_eddy_index = orig_eddy_count(date_index) + fake_eddy_count(date_index);
                fake_eddy_count(date_index) = fake_eddy_count(date_index) + 1;
                eddies{date_index}(fake_eddy_index) = eddies{date_index - 1}(eddy_before_index);
                eddies{date_index}(fake_eddy_index).Date = str2num(date);
                tracks{i}(j,4) = length(eddies{date_index});                
            end
        end
    end
    for k = 1:length(iterations_since_needed)
        if iterations_since_needed(k) > max_iterations && ~isempty(eddies{k})
            %disp(['Saving eddies on day ', num2str(k), ' back to file.']);
            path_cell = strsplit(eddies_names{k}, '/');
            file_name = path_cell{end};
            if ~exist(eddies_save_dir, 'dir')
                mkdir(eddies_save_dir);
            end
            personal_save([eddies_save_dir, file_name], eddies{k});
            fake_eddy_count(k) = 1;
            eddies{k} = [];
        end
    end
end

for i = 1:length(eddies)
    if ~isempty(eddies{i})
        %disp(['Saving eddies on day ', num2str(i), ' back to file.']);
        path_cell = strsplit(eddies_names{i}, '/');
        file_name = path_cell{end};
        if ~exist(eddies_save_dir, 'dir')
            mkdir(eddies_save_dir);
        end
        personal_save([eddies_save_dir, file_name], eddies{i});
        eddies{i} = [];
    end
    if ~has_been_loaded(i)
        %disp(['Saving non-loaded eddies on day ', num2str(i), ' back to file.']);
        vars = load(eddies_names{i});
        s = fieldnames(vars);
        path_cell = strsplit(eddies_names{i}, '/');
        file_name = path_cell{end};
        if ~exist(eddies_save_dir, 'dir')
            mkdir(eddies_save_dir);
        end
        personal_save([eddies_save_dir, file_name], vars.(s{1}));
    end
end


%% now save the altered tracks:

if strcmp(type, 'cyclonic') == 1
    cyclonic_tracks = tracks;%#ok
    save([tracks_save_dir 'cyclonic_tracks_processed.mat'], 'cyclonic_tracks'); 
else
    anticyc_tracks = tracks;%#ok
    save([tracks_save_dir 'anticyc_tracks_processed.mat'], 'anticyc_tracks');
end

end
%% wrapper function to save eddies in parfor:

function personal_save(eddies_path, eddies)%#ok
save(eddies_path, 'eddies');
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

function [eddies, orig_eddy_count] = fetch_eddies(eddies, eddies_names, index, orig_eddy_count, eddies_save_dir)
if index < 1 || index > length(eddies)
    disp(['Date index is ', num2str(index)]);
    error('Date index outside of eddy bounds.');
end
if isempty(eddies{index})
    %disp(['Loading eddies on day ', num2str(index)]);
    path_cell = strsplit(eddies_names{index}, '/');
    file_name = path_cell{end};
    if exist([eddies_save_dir, file_name], 'file')
        vars = load([eddies_save_dir, file_name]);
        s = fieldnames(vars);
        eddies{index} = vars.(s{1});
    else
        vars = load(eddies_names{index});
        s = fieldnames(vars);
        eddies{index} = vars.(s{1});
    end
    orig_eddy_count(index) = length(eddies{index});
end
end