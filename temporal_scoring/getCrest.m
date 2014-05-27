function [ end_index, min_index ] = getCrest( time_slice, begin_index, threshold )
%GETTROUGH Get crest for anticyclonic eddy
%   Detailed explanation goes here

end_index = begin_index;
n = length(time_slice);
while end_index < n && (time_slice(end_index) - time_slice(end_index+1)) <= threshold
    end_index = end_index + 1;
end

min_index = end_index;

while end_index < n && (time_slice(end_index) - time_slice(end_index+1)) >= threshold
    end_index = end_index + 1;
end

end