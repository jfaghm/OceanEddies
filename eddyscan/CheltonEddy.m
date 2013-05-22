classdef CheltonEddy
    %CHELTONEDDY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Stats;
        Lat;
        Lon;
        Amplitude;
        ThreshFound;
        MeanGeoSpeed; % cm/s
        SurfaceArea; %In sqkm.
        Cyc;
    end
    
    properties(Hidden=true)
        IsEmpty;
    end
    
    
    methods
        function obj = CheltonEddy(STATS, amplitude, lat, lon, thresh, ...
                sa, cyc, geospeed)
            if nargin
                obj.Stats = STATS;
                obj.Lat = lat;
                obj.Lon = lon;
                obj.Amplitude = amplitude;
                obj.ThreshFound = thresh;
                obj.SurfaceArea = sa;
                obj.IsEmpty = false;
                obj.Cyc = cyc;
                obj.MeanGeoSpeed = geospeed;
            else
                obj.Stats = regionprops([0 1; 0 0], 'BoundingBox', 'Centroid','ConvexArea', 'EquivDiameter', 'Area', 'PixelIdxList', 'PixelValues', 'FilledImage', 'MaxIntensity');
                obj.Lat = Nan;
                obj.Lon = NaN;
                obj.Amplitude = NaN;
                obj.ThreshFound = NaN;
                obj.SurfaceArea = NaN;
                obj.Cyc = 0;
                obj.IsEmpty = true;
                obj.MeanGeoSpeed = NaN;
            end
        end
    end
    
end

