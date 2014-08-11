function [ extrema ] = get_extrema( ssh, cyc )
%GET_EXTREMA Returns a matrix containing all of the minima or maxima
%(depending on the value of cyc) in a 5x5 matrix within the 2D ssh field.
% ssh: ssh slice containing NaNs for land
% cyc: 1 for anticyclonic, -1 for cyclonic

    padded = [ssh(:,end-1:end) ssh(:,:) ssh(:,1:2)];
    padded(isnan(padded)) = cyc*-Inf;
    padded = padarray(padded, [1, 1], cyc*-Inf);
    n = ones(5); n(3, 3) = 0;
    padded = cyc .* padded; % Want to find right extrema for cyclonic and anticyc eddies

    extrema = padded > imdilate(padded, n);
    extrema = extrema(2:end-1, 4:end-3);
end

