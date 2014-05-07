function [lat, lon] = weighted_centroid_irregular_grid(ssh, pixellist, pixelidxlist, cyc, lats, lons)
%WEIGHTED_CENTROID_IRREGULAR_GRID Returns the location of the weighted centroid for the
%pixels provided
    ssh = cyc * ssh;
    shift = min(ssh(pixelidxlist));
    
    x = pixellist(:, 1);
    y = pixellist(:, 2);
    
    if min(y) == 1 && max(y) == size(ssh,2)
        y(y > size(ssh,2)/2) = y(y > size(ssh,2)/2) - size(ssh,2);
    end
    
    mask = ~isnan(ssh(pixelidxlist));
    intensities = ssh(pixelidxlist)+shift;
    intensities = intensities - min(intensities); % should start from 0
    
    xbar = sum(x(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    ybar = sum(y(mask) .* intensities(mask).^2) / sum(intensities(mask).^2);
    
    if ybar <= 0
        ybar = ybar + size(ssh,2);
    end

    x_lower = floor(xbar);
    x_upper = ceil(xbar);
    if x_lower == 0
        lat = lats(1);
    elseif x_upper == length(lats) + 1
        lat = lats(end);
    else
        lat_lower = lats(x_lower);
        lat_upper = lats(x_upper);
        lat = lat_lower + (lat_upper - lat_lower) * (xbar - x_lower) / (x_upper - x_lower);
    end
    
    y_lower = floor(ybar);
    y_upper = ceil(ybar);
    if y_lower == 0
        lon = lons(1);
    elseif y_upper == length(lons) + 1
        lon = lons(end);
    else
        lon_lower = lons(y_lower);
        lon_upper = lons(y_upper);
        if lon_upper - lon_lower > 180
            lon_upper = lon_upper - 360;
        elseif lon_lower - lon_upper > 180
            lon_lower = lon_lower - 360;
        end
        lon = lon_lower + (lon_upper - lon_lower) * (ybar - y_lower) / (y_upper - y_lower);
    end

end
