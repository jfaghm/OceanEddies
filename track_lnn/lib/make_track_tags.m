function [ tags ] = make_track_tags( tracks, eddy_types )
%MAKE_TRACK_TAGS Make tags for eddy in tracks based on eddy type cell array
%   Detailed explanation goes here

tags = cell(size(tracks));
for i = 1:length(tracks);
    tags{i} = nan(size(tracks{i}, 1), 1);
    for j = 1:size(tracks{i}, 1)
        date_index = tracks{i}(j, 3);
        eddy_index = tracks{i}(j, 4);
        tags{i}(j) = eddy_types{date_index}(eddy_index);
    end
end

end

