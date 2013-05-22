function mean_speed = mean_geo_speed(ssh, pixels, lat, lon)
%MEAN_GEO_SPEED Returns the mean geostrophic speed for pixels.
% lat and lon should yield the correct values for indices of ssh.
    g = 980.665; % cm/s
    omega = 7.2921e-5;
    us = zeros(size(pixels));
    vs = zeros(size(pixels));
    [x, y] = ind2sub(size(ssh), pixels);
    lats = lat(x);
    f = 2*omega*sin(lats);
    f(f == 0) = 2*omega*sin(0.25); % f is coriolis frequency
    for i = 1:length(pixels)
        % Compute vs and us by taking the average with the difference of
        % the next and previous pixel. Take into account wrap around for
        % lons and caps for lats
        dSSH_y = ssh(x(i), mod(y(i),size(ssh, 2))+1) - ...
            ssh(x(i), mod(y(i)-2,size(ssh, 2))+1);
        dSSH_x = ssh(min(x(i)+1,size(ssh,1)), y(i)) - ...
            ssh(max(x(i)-1, 1), y(i));
        dy = distance(lat(x(i)), lon(mod(y(i), size(ssh, 1))+1), ...
            lat(x(i)), lon(mod(y(i)-2, size(ssh, 1))+1)) * 6371.01 * ...
            100000 * pi / 180;
        dx = (min(x(i)+1, size(ssh, 1))-max(1,x(i)-1))*111.12*100000* ...
            180/(length(lats)-1);
        vs(i) = -g*(dSSH_y)/(2*f(i)*dy);
		us(i) =  g*(dSSH_x)/(2*f(i)*dx);
    end
    speeds = sqrt(us.^2+vs.^2);
    mean_speed = mean(speeds);
end

