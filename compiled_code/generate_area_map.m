function [area_map] = generate_area_map(lat_number, lon_number)
% Example: SSH grid is size 720x1440
% lat_number = 720
% lon_number = 1440
lat_bnds = create_bounds_for_lat_from_number(lat_number);
lon_bnds = create_bounds_for_lon_from_number(lon_number);
area_map = gen_area_map(lat_bnds, lon_bnds);
end

function [lat_bounds] = create_bounds_for_lat_from_number(lat_number)
lat_bounds = zeros(2,lat_number);
lat_bounds(1,1) = -90;
coeff = 180 / lat_number;
for i = 1:lat_number-1
    lat_bounds(2,i) = lat_bounds(1,i) + coeff;
    lat_bounds(1,i+1) = lat_bounds(2,i);
end
lat_bounds(2,lat_number) = 90;
end

function [lon_bounds] = create_bounds_for_lon_from_number(lon_number)
lon_bounds = zeros(2,lon_number);
lon_bounds(1,1) = 0;
coeff = 360 / lon_number;
for i = 1:lon_number-1
    lon_bounds(2,i) = lon_bounds(1,i) + coeff;
    lon_bounds(1,i+1) = lon_bounds(2,i);
end
lon_bounds(2,lon_number) = 360;
end

function [area_map] = gen_area_map(lat_bnds, lon_bnds)
% Returns an area map for the given latitude and longitude bounds
area_map = zeros(length(lat_bnds), 1);
lon1 = lon_bnds(1,1);
lon2 = lon_bnds(1,2);
earth_ellipsoid = referenceSphere('earth', 'km');
for i = 1:length(lat_bnds)
    area_map(i) = areaquad(lat_bnds(1,i), lon1, lat_bnds(2,i), lon2, earth_ellipsoid);
end
end