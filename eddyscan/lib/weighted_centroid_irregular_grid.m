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

    if round(xbar) == 0
        xbar = 1;
    elseif round(xbar) == length(lats) + 1
        xbar = length(lats);
    end
    lat = lats(round(xbar));
    
    if round(ybar) == 0
        ybar = 1;
    elseif round(ybar) == length(lons) + 1
        ybar = length(lons);
    end
    lon = lons(round(ybar));

end
