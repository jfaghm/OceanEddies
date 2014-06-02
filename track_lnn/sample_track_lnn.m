% eddy_dir is the directory where you save the eddies from eddy_scan function
eddy_dir = '';

% Assume variable dates is loaded, which is 1D array of dates of the eddies
cyc_eddies = cell(size(dates));

% Get eddies into a cell array
for i = 1:length(dates)
    temp = load([eddy_dir 'cyclonic_' num2str(dates(i)) '.mat']);
    cyc_eddies{i} = temp.eddies;
end

% Track eddies with track_lnn, 7 means this is weekly data. Use 1 for daily data
tracks = track_lnn(cyc_eddies, 7);