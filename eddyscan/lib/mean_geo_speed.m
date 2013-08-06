function mean_speed = mean_geo_speed(ssh, pixels, lat, lon)
%MEAN_GEO_SPEED Returns the mean geostrophic speed for pixels.
% lat and lon should yield the correct values for indices of ssh.
    g = 980.665; % cm/s
    omega = 7.2921e-5;
    [x, y] = ind2sub(size(ssh), pixels);
    lats = lat(x);
    f = 2*omega*sin(lats);
    f(f == 0) = 2*omega*sin(0.25); % f is coriolis frequency
    
    dSSH_y = ssh(sub2ind(size(ssh), x, mod(y, size(ssh, 2))+1)) - ...
        ssh(sub2ind(size(ssh), x, mod(y-2, size(ssh, 2))+1));
    dSSH_x = ssh(sub2ind(size(ssh), min(x+1, zeros(size(x)) + size(ssh, 1)), y))...
        - ssh(sub2ind(size(ssh), max(x-1, ones(size(x))), y));
    dy = distance(lat(x), lon(mod(y, size(ssh, 1))+1), lat(x), lon(mod(y-2, size(ssh, 1))+1)) .* ...
        6371.01 .* 1000000 .* pi ./ 180;
    dx = (min(x+1, size(ssh, 1)) - max(1, x-1)) .* 111.12 .* 1000000 .* 180 ./ (length(lats) - 1);
    vs = -g .* (dSSH_y) ./ (2.*f .* dy);
    us = g .* (dSSH_x) ./ (2 .* f .* dx );
    speeds = sqrt(us .^2 + vs .^2);
    mean_speed = nanmean(speeds);
end