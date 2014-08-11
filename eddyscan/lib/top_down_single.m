function [ eddies ] = top_down_single(ssh_data, lat, lon, areamap, cyc, varargin)
%   Finds eddies using the Top Down approach, see more at EddyScan Paper
%   Will return an array of struct's that contain the eddy data.
%   ssh_data: A 2D array of double's that contain the sea surface heights (latsxlons)
%   lat: A 1D array of double's that gives the latitude for a given index (dimension should match
%         that of ssh_data)
%   lon: A 1D array of double's that gives the longitude for a given index (dimension should match
%         that of ssh_data)
%   areamap: A 2D array that refer to the area of each pixel in SSH data (should have same size as ssh), or 1D array
%            that refer to area of each pixel for a specific lat in a regular grid (pixeld have same area for the same
%            latitude)
%   cyc:     Pass 1 to output anticyclonic eddies or -1 to output cyclonic eddies

%   Optional parameters:
%
%   'sshUnits': The units the SSH data is in. top_down_single is built to
%   work natively on centimeter SSH data. Valid parameters are 'meters' and
%   'centimeters'. If the paramater passed in is 'meters', the SSh data
%   will be multiplied by 100. No changes will be made if the paramater
%   passed in is 'centimeters'. The default value of 'ssh_units'
%   is centimeters
%   'threshStart': lower Bound of thresholding range, -100 cm when cyc == 1,
%                   100 cm when cyc == -1 by default
%   'threshEnd': upper Bound of thresholding range, 100 cm
%                 when cyc == 1 and -100 cm when cyc == -1 by default
%   'thresholdStep': step size of thresholding, 1 cm by default,
%   'convexity_ratio_limit': convexity ratio to check criteria, 0.85 by
%                            default
%   'minimumArea': minimum number of pixels for an eddy, used for
%                  validating eddies, 9 by default
%   'maximumArea': maximum number of pixels for an eddy, used for
%                  validating eddies, 1000 by default
%   'minimumAmplitude': minimum value of amplitude for an eddy, used for
%                       validating eddies, 1 by default
%   'minimumExtrema': minimum number of extremas for an eddy, used for
%                     validating eddies, 1 by default
%   'isPadding': whether or not to pad SSH data, should be true when scanning SSH data of the whole map. Set to false if
%                only partial SSH data is used.

addpath('lib/')
%%  Parse parameters
p = inputParser;
defaultMinPixelSize = 9;
defaultMaxPixelSize = 1000;
defaultSSHUnits = 'centimeters';
if(cyc == 1)
    defaultThresholdStart = -100;
    defaultThresholdEnd = 100;
    defaultThresholdStep = 1;
else
    defaultThresholdStart = 100;
    defaultThresholdEnd = -100;
    defaultThresholdStep = -1;
end
defaultPaddingFlag = true;
defaultConvRatioLimit = 0.85;
defaultMinAmp = 1;
defaultMinExtre = 1;
addRequired(p, 'ssh_data');
addRequired(p, 'lat');
addRequired(p, 'lon');
addRequired(p, 'areamap');
addRequired(p, 'cyc');
addParameter(p, 'sshUnits', defaultSSHUnits);
addParameter(p, 'minimumArea', defaultMinPixelSize, @isnumeric);
addParameter(p, 'maximumArea', defaultMaxPixelSize, @isnumeric);
addParameter(p, 'thresholdStep', defaultThresholdStep, @isnumeric);
addParameter(p, 'thresholdStart', defaultThresholdStart, @isnumeric);
addParameter(p, 'thresholdEnd', defaultThresholdEnd, @isnumeric);
addParameter(p, 'isPadding', defaultPaddingFlag);
addParameter(p, 'convexRatioLimit', defaultConvRatioLimit, @isnumeric);
addParameter(p, 'minAmplitude', defaultMinAmp, @isnumeric);
addParameter(p, 'minExtrema', defaultMinExtre, @isnumeric);
parse(p, ssh_data, lat, lon, areamap, cyc, varargin{:});
SSH_Units = p.Results.sshUnits;
minimumArea = p.Results.minimumArea;
maximumArea = p.Results.maximumArea;
thresholdStep = p.Results.thresholdStep;
thresholdStart = p.Results.thresholdStart;
thresholdEnd = p.Results.thresholdEnd;
isPadding = p.Results.isPadding;
convexRatioLimit = p.Results.convexRatioLimit;
minAmplitude = p.Results.minAmplitude;
minExtrema = p.Results.minExtrema;
disp(['SSH_Units: ', SSH_Units]);
%% parameters validity check

if strcmp(SSH_Units, 'meters')
    ssh_data = ssh_data * 100;
elseif strcmp(SSH_Units, 'centimeters')
    max_val = max(ssh_data(:));
    min_val = max(ssh_data(:));
    if max_val < 1 && min_val > -1
        ssh_data = ssh_data * 100;
    elseif max_val < 100 && min_val > -100
        
    else
        error('Could not figure out what units the SSH data provided is in. Please specify it as an additional parameter: sshUnits');
    end
end

thresholdStep = abs(thresholdStep);
switch cyc
    case 1
        disp('You are scanning for anticyclonic eddies');
    case -1
        disp('You are scanning for cyclonic eddies');
        thresholdStep = - thresholdStep;
    otherwise
        error('Invalid cyc');
end
disp('The units for SSH data is in centimeters by default. This code is designed to automatically adjust input data to units of centimeters.')
if(cyc == 1 && (thresholdStart >= thresholdEnd))
    error('for anticyclonic, thresholding values need to be increasing, e.g., -100:1:100');
end
if(cyc == -1 && (thresholdStart <= thresholdEnd))
    error('for cyclonic, thresholding values need to be decreasing, e.g., 100:1:-100');
end


disp(['minimum eddy pixel size: ' num2str(minimumArea)])
disp(['maximum eddy pixel size: ' num2str(maximumArea)])
disp(['minimum eddy amplitude: ' num2str(minAmplitude)])
disp(['minimum number of extremas: ' num2str(minExtrema)])
disp(['convexity ratio limit: ' num2str(convexRatioLimit)])
disp(['thresholding range ' num2str(thresholdStart) ' : ' num2str(thresholdStep) ' : ' num2str(thresholdEnd)])
%% Check if the grid is regular (differences between lats and lons are equal)
lat_diffs = lat(2:end) - lat(1:end-1);
lat_diffs2 = lat_diffs(2:end) - lat_diffs(1:end-1);
lon_diffs = lon(2:end) - lon(1:end-1);
lon_diffs(lon_diffs <= -180) = lon_diffs(lon_diffs <= -180) + 360;
lon_diffs(lon_diffs >= 180) = lon_diffs(lon_diffs >= 180) - 360;
lon_diffs = abs(lon_diffs);
lon_diffs2 = lon_diffs(2:end) - lon_diffs(1:end-1);
if all(lat_diffs2 == 0) && all(lon_diffs2 == 0)
    geo_raster_lat_limit = [lat(1) lat(end)];
    if lon(1) > lon(end)
        geo_raster_lon_limit = [lon(1) (360 + lon(end))];
    else
        geo_raster_lon_limit = [lon(1) lon(end)];
    end
    R = georasterref('LatLim', geo_raster_lat_limit, 'LonLim', geo_raster_lon_limit, 'RasterSize', ...
        size(ssh_data), 'ColumnsStartFrom', 'south', 'RowsStartFrom', 'west');
else
    % Use normal indexing to get eddy's centroid
    R = [];
end


%% set up
if isPadding
    %extend ssh data
    %extended data = |first 200 columns of ssh | ssh | last  200 columns of ssh |
    ssh_extended = zeros(size(ssh_data,1),400+size(ssh_data,2));
    ssh_extended(:,1:200) = ssh_data(:,(end-199):end);
    ssh_extended(:,201:(size(ssh_data,2)+200)) = ssh_data;
    ssh_extended(:,(201+size(ssh_data,2)):end) = ssh_data(:,1:200);
else
    ssh_extended = ssh_data;
end

sshnan = sum(isnan(ssh_data(:))) > 0;
if sshnan  % if any NAN data found in SSH, mask them out
    bwMask = ~isnan(ssh_extended);
else      % if no NAN data, mask out highest SSH
    landval = max(ssh_data(:));
    bwMask = ~(ssh_extended == landval);
end
ssh_extended_data = ssh_extended;
% convert extended data to intensity ranging from -100 to 100
ssh_extended = mat2gray(ssh_extended,[-100 100]);

%set thresholding values
realThresh = thresholdStart : thresholdStep : thresholdEnd;


% used to test convexity later in thresholdTD.m Pre-compute here to
% aviod duplicate computations in parfor loop
areas = zeros(1,91);
areas(1:10) = 200;
areas(11:81) = 200:-2.6:18;
areas(82:91) = 18;
areas = pi()*areas.^2;

eddies = new_eddy();
%% Nested loop
for i = 1:length(realThresh)
    % set up
    currentThresh = realThresh(i);
    threshRange = (currentThresh + 100) / 200;
    bw = im2bw(ssh_extended, threshRange);
    if cyc==-1
        bw = imcomplement(bw);
    end
    bw = bw.*bwMask;
    CC = bwconncomp(bw);
    lmat = labelmatrix(CC);
    bw_mask_changes = cell(1, CC.NumObjects); % used tp store every bw mask returned from inner loop and combine them together to to used by next outer loop
    
    % only create pool when there is no pool
    %current_poor = gcp('nocreate'); % if no poor, create one
    %if(isempty(current_poor))
    %    parpool;
    %end
    %disp(['Scanning at threshold ', num2str(currentThresh), ' with ', num2str(CC.NumObjects), ' objects']);
    % parfor loop to iterate all CCs under current thresholding values
    parfor n=1:CC.NumObjects
        [eddy, bw_mask_changes{n}] = thresholdTD(cyc, ssh_data, ssh_extended,ssh_extended_data, currentThresh, lat, lon, R, areamap, minimumArea, ...
            maximumArea, convexRatioLimit, minAmplitude, minExtrema, bwMask, areas, lmat, n);
        if(~isempty(eddy))
            eddies = horzcat(eddies, eddy);
        end
    end
    
    % integate all single bw_masks togetger eith old one
    updated_bw_mask = bwMask;
    for j = 1:length(bw_mask_changes)
        updated_bw_mask = updated_bw_mask.*bw_mask_changes{j};
    end
    
    bwMask = updated_bw_mask;
end

mask = cellfun('isempty', {eddies.Lat});
eddies = eddies(~mask);
end

