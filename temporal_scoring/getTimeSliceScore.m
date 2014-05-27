function [ scores, shifts ] = getTimeSliceScore( ts, eddy_type, is_smoothing )
%GETTIMESLICESCORE Get scores and shifts of points in the time slice
%   Score is defined as cup_area / (abs(shift) + 1), where area is the area of the cup below the lower edge (cyclonic)
%   or above the upper edge (anticyclonic), shift is the distance from the current point to the extremum
% Params:
%   ts: timeslice (1d array)
%   eddy_type: 'cyc'/'ant'
%   is_smoothing: whether to smooth the data before computing shifts and scores. Smoothing will take sometime to compute
%   so you could smooth ssh data before using this function and set is_smoothing to false.

scores = nan(size(ts));
shifts = nan(size(ts));

if any(isnan(ts))
    return
end

if is_smoothing
    ts = smooth(ts, 3);
end

thresh = 0;

%trim beginning
begin_index = 1;
if strcmp(eddy_type, 'cyc')
    f = @(ts, i)(getTrough(ts, i, thresh));   %create getTrough function handle
    while begin_index < length(ts) && (ts(begin_index) - ts(begin_index+1)) < thresh
        % Go to local maximum
        begin_index = begin_index+1;
    end
else
    f = @(ts, i)(getCrest(ts, i, thresh));    %create getCrest function handle
    while begin_index+1 <= length(ts) && (ts(begin_index) - ts(begin_index+1)) > thresh
        % go to local minimum
        begin_index = begin_index+1;
    end
end

[end_index, min_index] = f(ts, begin_index);
[scores(begin_index:end_index), shifts(begin_index:end_index)] = ...
    getScores(ts, begin_index, end_index, min_index, eddy_type);

begin_index = end_index + 1;
while(begin_index <= length(ts))
    [end_index, min_index] = f(ts, begin_index);
    [scores(begin_index:end_index), shifts(begin_index:end_index)] = ...
        getScores(ts, begin_index, end_index, min_index, eddy_type);
    begin_index = end_index + 1;
end

end


function [scores, shifts] = getScores(ts, begin_index, end_index, min_index, eddy_type)
%Get the scores and shifts of the timeslice from begin index to end index
if strcmp(eddy_type, 'cyc')
    lower_end = min(ts(begin_index), ts(end_index));
else
    lower_end = max(ts(begin_index), ts(end_index));
end

ts_of_interest = ts(begin_index:end_index);
shifts = (begin_index:end_index) - min_index;

if strcmp(eddy_type, 'cyc')
    areas = sum(lower_end - (ts_of_interest(ts_of_interest <= lower_end)));
else
    areas = sum((ts_of_interest(ts_of_interest >= lower_end)) - lower_end);
end

scores = areas ./ (abs(shifts) + 1);

end
