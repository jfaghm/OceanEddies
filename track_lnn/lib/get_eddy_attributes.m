function [ amps, geospeeds, lats, lons, pxcounts, pixels, surface_areas ] = get_eddy_attributes( eddy_dir, eddy_file_initial, dates)
%GET_EDDY_ATTRIBUTES Summary of this function goes here
%   Detailed explanation goes here

amps = cell(size(dates));
geospeeds = cell(size(dates));
lats = cell(size(dates));
lons = cell(size(dates));
pxcounts = cell(size(dates));
pixels = cell(size(dates));
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
    stats = [eddies.Stats];
    pxcounts{i} = [stats.Area];
    pixels{i} = {stats.PixelIdxList};
end

end

