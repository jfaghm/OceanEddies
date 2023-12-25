% This script generates an Animation to identify desired edd(y)ies for
% further analysis
%
% NOTE: SLA overlaid by contours of 0.1 0.4 and 0 m
% - with center position obtained from the Algorithms
% NOTE: This is only for cyclonic eddies, for anticyclonic eddies make
% changes, suggested below
%===============
% Ramkrushn Patel, IMAS/UTAS
%===============

% CONTENTS:
% 1) Loading Sea Surface Height data
% 2) Loading Eddies locations
% 3) Preparing Movie

%% 1) Loading Sea Surface Height data
clear; clc;

old_path = pwd;
ssh_path =  '~/Desktop/Satellite_data/JoanModelRun/';
cd(ssh_path)
%
filenames = dir('ssh_*.mat');
nfiles = length(filenames);
%
load lon.mat
load lat.mat
load dates.mat
%
cd(old_path)

%% 2) Loading Eddies location

eddy_path = '~/Documents/MATLAB/OceanEddies-master/MyRuns/JoanEddy/';
fname = 'chelton_structured_tracks.mat';
load([eddy_path, fname])

% Extracting variables
e_sign = eddies_t.cyc;
% get only cyclonic eddies/anticyclonic eddies
cyc = e_sign == 1; % -1 for cyclonic % ---------- Change here for type of eddies 
%
e_lon = eddies_t.x(cyc); % eddies center longitude
e_lat = eddies_t.y(cyc); % eddies center latitude
e_trackday = eddies_t.track_day(cyc); % tracked date
e_id = eddies_t.id(cyc); % eddies id

% Loading coastlines
c = load('~/Documents/MATLAB/Construction_Site/global_coastline.txt'); % Coast Line

%% 3) Preparing movie
close all
h = figure(11);
set(h, 'Position', [100 678 560 420])
% ==Prepare Video file==
vidObj = VideoWriter('EddyAnimationACyc.avi'); %==== Change file name if you re-run the script
fps = 7;
vidObj.FrameRate = fps;
vidObj.Quality = 100;
open(vidObj)
%
for fInd = 1:nfiles
    disp(['Current File: ', int2str(fInd)])
    %
    load([ssh_path, filenames(fInd).name]) % SLA data
    time = num2str(dates(fInd));
    time = datestr(datenum(time,'yyyymmdd'));
    %
    % Getting eddies for the day
    da_id = dates(fInd);
    ind = find(e_trackday == da_id);

    % Plotting
    % Background MSLA 
    pcolor(lon, lat, data); shading interp 
    caxis([-0.5, 0.5])
    colormap(redblue(length(-0.5:0.02:0.5) - 1))
    colorbar
    hold on
    % Plotting eddies
    plot(e_lon(ind), e_lat(ind), '.m', 'MarkerSize', 20) 
    text(e_lon(ind), e_lat(ind), num2str(e_id(ind)),'color','k','fontsize', 14, 'fontweigh','bold') % numbering eddies
    % Ensuring closed contours
    contour(lon, lat, data, [-0.1, -0.1], '-', 'linewidth', 1, 'color', 'b');
    contour(lon, lat, data, [0.1, 0.1], '-', 'linewidth', 1, 'color', 'r');
    
    % ======
    plot(c(:,1), c(:,2), 'k-', 'LineWidth', 3);
    s1 = sprintf('Day %d Date: %s', fInd, time);
    title(s1, 'fontsize', 14, 'fontweigh', 'bold')
    M(fInd) = getframe(h); %#ok 
    clf
    clear data time s1 ind da_id
end
writeVideo(vidObj, M)
close(vidObj)
clear M h
