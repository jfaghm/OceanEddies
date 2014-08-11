function [lat, lon] = weighted_centroid(ssh, pixellist, pixelidxlist, cyc, R)
%WEIGHTED_CENTROID Returns the location of the weighted centroid for the
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
    
    [lat, lon] = pix2latlon(R, xbar, ybar);

end

