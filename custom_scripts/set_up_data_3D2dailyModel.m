function set_up_data_3D2dailyModel(sla, lon, lat, time, save_path)
% This function prepares daily SLA file from 3D SLA file Provided:
% 3D file is .mat file and in the same format as stipulated here.
% File must contain following variable in exact names: time, lon, lat, sla
% Dimension of data: example time 1461x1, lon 301x1, lat 141x1 and sla
% 1461x141x301
% WHAT THIS DOES:
% 1: save lat.mat
% 2: save lon.mat
% 3: save dates.mat
% 4: save area_map.mat
% 5: save SLA data in daily format

disp( 'Saving LONGITUDE in lon.mat file')
save([save_path, 'lon.mat'], 'lon')

disp( 'Saving LATITUDE in lat.mat file')
save([save_path, 'lat.mat'], 'lat')

disp( 'Saving DATES in dates.mat file')
dates = create_dates(time);
save([save_path, 'dates.mat'], 'dates')
%
disp( 'Computing AREAMAP and storing in area_map.mat file')
create_area_map(lat, lon, save_path);

disp('Storing SLA data in daily format:  ssh_yyyymmdd.mat')

parfor i = 1:length(time)
    data = squeeze(sla(i,:,:));
    date = num2str(dates(i));
    par_save([save_path, 'ssh_', date, '.mat'], data)
end
end
% Supporting functions
function par_save(filename, data)
save(filename, 'data');
end
% creating date array
function dates = create_dates(time)
da = datestr(time, 26);
ndate = length(da);
da(:,[5,8]) = [];
dates = NaN(ndate,1);
parfor ii = 1:ndate
    dates(ii) = str2double(da(ii,:));
end
end
% computation of area map
function create_area_map(latitude, longitude, save_path)
area_map = zeros(length(latitude), 1);
earth_ellipsoid = referenceSphere('earth', 'km');
extlat = latitude;
extlat(end + 1) = extlat(end) + mean(diff(latitude));
nlat = length(extlat);
for i = 1:(nlat-1)
    area_map(i) = areaquad(extlat(i), longitude(1), extlat(i+1), longitude(2), earth_ellipsoid);
end
save([save_path,'area_map.mat'],'area_map')
end