function reformatted_data = reformat_track_data_to_chelton(eddy_dir, dates, anticyclonic_tracks, cyclonic_tracks)
%PREPARE_EDDY_DATA_FOR_VIEWER Prepare data for the viewer
% Input:
%   viewer_data_save_dir: where to save data for track viewer
%   dates: 1D array of dates for data
%   eddy_dir: directory where you save eddy from eddyscan
%   cyclonic_tracks: tracks for cyclonic eddies
%   anticyclonic_tracks: tracks for anticyclonic eddies
%   ssh_dir: directory where you save ssh data slices

% Cyclonic attributes
disp('getting eddies attributes, will take a long time (about 30mins for 900 time slices)');

 if ~isempty(cyclonic_tracks)
     [ cyc_amps, cyc_geospeeds, cyc_lats, cyc_lons, cyc_surface_areas ] = ...
         get_eddy_attributes(eddy_dir, 'cyclonic', dates);

    cyc_eddy_counts = zeros(length(cyc_lats), 1);
    for i = 1:length(cyc_lats)
        cyc_eddy_counts(i) = length(cyc_lats{i});
    end

    cyc_eddy_track_indexes = get_eddy_track_index(cyc_eddy_counts, cyclonic_tracks);
end

% Anticyclonic attributes
if ~isempty(anticyclonic_tracks)
    [ ant_amps, ant_geospeeds, ant_lats, ant_lons, ant_surface_areas ] = ...
        get_eddy_attributes(eddy_dir, 'anticyc', dates);

    ant_eddy_counts = zeros(length(ant_lats), 1);
    for i = 1:length(ant_lats)
        ant_eddy_counts(i) = length(ant_lats{i});
    end

    ant_eddy_track_indexes = get_eddy_track_index(ant_eddy_counts, anticyclonic_tracks);
end

n_edd=sum(ant_eddy_counts)+sum(cyc_eddy_counts);
%find max ac id
max_acid=0;
for m=1:length(ant_eddy_counts)
    tmp=max(ant_eddy_track_indexes{m});
    if tmp>max_acid
        max_acid=tmp;
    end
end

[eddies_t.x,eddies_t.y,eddies_t.amp,eddies_t.area,eddies_t.u,...
eddies_t.area,eddies_t.Ls,eddies_t.id,eddies_t.cyc,eddies_t.track_day]=deal(nan(n_edd,1));
st=1;
for n=1:length(dates)
    disp(['Date: ', num2str(n)]);
    disp(['grabbing ant eddies from ', num2str(st), ' to ', num2str(ant_eddy_counts(n)+st-1)]);
    eddies_t.x(st:ant_eddy_counts(n)+st-1)=ant_lons{n};
    eddies_t.y(st:ant_eddy_counts(n)+st-1)=ant_lats{n};
    eddies_t.amp(st:ant_eddy_counts(n)+st-1)=ant_amps{n};
    eddies_t.u(st:ant_eddy_counts(n)+st-1)=ant_geospeeds{n};
    eddies_t.area(st:ant_eddy_counts(n)+st-1)=ant_surface_areas{n};
    eddies_t.Ls(st:ant_eddy_counts(n)+st-1)=sqrt(ant_surface_areas{n}./pi);
    eddies_t.cyc(st:ant_eddy_counts(n)+st-1)=1;
    %eddies_t.track_day(st:ant_eddy_counts(n)+st-1)=ac.jd{n};
    eddies_t.id(st:ant_eddy_counts(n)+st-1)=ant_eddy_track_indexes{n};

    st=st+ant_eddy_counts(n);
    disp(['grabbing cyc eddies from ', num2str(st), ' to ', num2str(cyc_eddy_counts(n)+st-1)]);
    eddies_t.x(st:cyc_eddy_counts(n)+st-1)=cyc_lons{n};
    eddies_t.y(st:cyc_eddy_counts(n)+st-1)=cyc_lats{n};
    eddies_t.amp(st:cyc_eddy_counts(n)+st-1)=cyc_amps{n};
    eddies_t.u(st:cyc_eddy_counts(n)+st-1)=cyc_geospeeds{n};
    eddies_t.area(st:cyc_eddy_counts(n)+st-1)=cyc_surface_areas{n};
    eddies_t.Ls(st:cyc_eddy_counts(n)+st-1)=sqrt(cyc_surface_areas{n}./pi);
    eddies_t.cyc(st:cyc_eddy_counts(n)+st-1)=-1;
    %eddies_t.track_day(st:cyc_eddy_counts(n)+st-1)=cc.jd{n};
    eddies_t.id(st:cyc_eddy_counts(n)+st-1)=max_acid+cyc_eddy_track_indexes{n};

    st=st+cyc_eddy_counts(n);
end

ii=find(isnan(eddies_t.id));
eddies_t.x(ii)=[];
eddies_t.y(ii)=[];
eddies_t.amp(ii)=[];
eddies_t.u(ii)=[];
eddies_t.area(ii)=[];
eddies_t.Ls(ii)=[];
eddies_t.cyc(ii)=[];
eddies_t.track_day(ii)=[];
eddies_t.id(ii)=[];

reformatted_data = eddies_t;
end

function [ amps, geospeeds, lats, lons, surface_areas ] = get_eddy_attributes( eddy_dir, eddy_file_initial, dates)
%GET_EDDY_ATTRIBUTES Summary of this function goes here
%   Detailed explanation goes here

amps = cell(size(dates));
geospeeds = cell(size(dates));
lats = cell(size(dates));
lons = cell(size(dates));
surface_areas = cell(size(dates));
for i = 1:length(dates)
    disp(i)
    try
        temp = load([eddy_dir eddy_file_initial '_' num2str(dates(i)) '.mat']);
    catch
        disp(['Error loading file: ', eddy_dir, eddy_file_initial, '_', num2str(dates(i)), '.mat']);
        continue;
    end
    names = fieldnames(temp);
    if length(names) == 1
        eddies = temp.(names{1});
    end
    amps{i} = [eddies.Amplitude];
    geospeeds{i} = [eddies.MeanGeoSpeed];
    surface_areas{i} = [eddies.SurfaceArea];
    lats{i} = [eddies.Lat];
    lons{i} = [eddies.Lon];
end
end

function [ track_indexes ] = get_eddy_track_index( eddy_counts, tracks )
%GET_EDDY_TRACK_INDEX Summary of this function goes here
%   Detailed explanation goes here

track_indexes = cell(size(eddy_counts));
for i = 1:length(eddy_counts)
    track_indexes{i} = nan(eddy_counts(i), 1);
end

for i = 1:length(tracks)
    curr_track = tracks{i};
    for j = 1:size(curr_track, 1)
        curr_date_index = curr_track(j, 3);
        curr_eddy_index = curr_track(j, 4);
        track_indexes{curr_date_index}(curr_eddy_index) = i;
    end
end
end