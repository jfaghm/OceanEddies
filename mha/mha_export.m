function [ data ] = mha_export(cyc, ant, dates)
%MHA_EXPORT Converts intermediate results from MHA to single table format.
%   cyc, ant: structs that contain the data outputted by MHA. (Should be
%   for same timesteps.
%   dates: array of dates used by MHA
    t0 = find(dates == cyc.start_date);
    cyc_tracks = cyc.tracks;
    ant_tracks = ant.tracks;
    l = length(cyc_tracks);
    x = zeros(1,length(cyc_tracks)+length(ant_tracks));
    y = zeros(1,length(cyc_tracks)+length(ant_tracks));
    
    for i = 1:length(cyc_tracks)
        y(i) = size(cyc_tracks{i}, 2);
    end
    x(1:l) = get_lengths(cyc_tracks);
    x(l+1:end) = get_lengths(ant_tracks);
    
    for i = 1:length(ant_tracks)
        y(i+l) = size(ant_tracks{i}, 2);
    end
    
    data = zeros(sum(x),max(y)+4);
    data(:,11:end) = -1;
    id = 0;
    pos = 1;
    
    for i = 1:length(cyc_tracks)
        id = i;
        data(pos:pos+x(id)-1, 1) = id;
        data(pos:pos+x(id)-1, 2) = 1:x(id);
        data(pos:pos+x(id)-1, 4) = -1;
        data(pos:pos+x(id)-1, 5:y(id)+4) = cyc_tracks{i}(1:x(id),:);
        pos = pos + x(id);
    end
    
    for i = 1:length(ant_tracks)
        id = i + l;
        data(pos:pos+x(id)-1, 1) = id;
        data(pos:pos+x(id)-1, 2) = 1:x(id);
        data(pos:pos+x(id)-1, 4) = 1;
        data(pos:pos+x(id)-1, 5:y(id)+4) = ant_tracks{i}(1:x(id),:);
        pos = pos + x(id);
    end
    
    t = dates(data(:,7)+t0-1);
    data(:,3) = juliandate(floor(t/10000), ...
        mod(floor(t/100), 100), ...
        mod(t, 100));
    data(:,7) = data(:,11);
    data(:,[5 6]) = data(:,[6 5]);
    t = data(:,10);
    data(:,10:11) = data(:,8:9);
    data(:,9) = t;
    data(:,8) = sqrt(t/pi);
    t = data(:,14);
    data(:,10:14) = data(:,9:13);
    data(:,9) = t;
end

function [ lens ] = get_lengths( tracks )
    is_mht = size(tracks{1},2) >= 8;
    lens = zeros(size(tracks));
    for i = 1:length(tracks)
        len = size(tracks{i},1);
        if is_mht && tracks{i}(end,8) == 1
            len = len - 1;
        end
        lens(i) = len;
    end
end

