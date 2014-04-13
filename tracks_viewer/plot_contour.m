function contour_plot = plot_contour(date, pixel_dir, eddy_indexes, backgroundData, eddy_type)
%PLOT_CONTOUR plot contours for current eddies in the track viewer

temp = load([pixel_dir 'lat.mat']);
lat = temp.lat;
temp = load([pixel_dir 'lon.mat']);
lon = temp.lon;

contour_mask = false(length(lat), length(lon));

if strcmp(eddy_type, 'ant')
    pixel_file = [pixel_dir 'anticyclonic/pixels_' num2str(date)];
else
    pixel_file = [pixel_dir 'cyclonic/pixels_' num2str(date)];
end
temp = load(pixel_file);
pixel_list = temp.data;

for i = 1:length(eddy_indexes)
    contour_mask(pixel_list{eddy_indexes(i)}) = true;
end

contour_mask = bwperim(contour_mask);

contour = nan(length(lat), length(lon));

if strcmp(eddy_type, 'ant')
    if ~isempty(backgroundData)
        contour(contour_mask) = max(backgroundData(:)) + 0.2 * range(backgroundData(:));
    else
        contour(contour_mask) = 1;
    end    
elseif strcmp(eddy_type, 'cyc')
    if ~isempty(backgroundData)
        contour(contour_mask) = min(backgroundData(:)) - 0.2 * range(backgroundData(:));
    else
        contour(contour_mask) = 0;
    end
else
    error('Not recognized eddy type');
end

contour_plot = pcolorm(lat, lon, contour);

end

