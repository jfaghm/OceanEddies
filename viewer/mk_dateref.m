function [ dateref ] = mk_dateref( tracks, dates )
%MK_DATEREF Creates datereference matrix for tracks. This stores track
% indicies for all tracks that are in the specific timestep.
    dateref = cell(size(dates));
    for i = 1:length(tracks)
        for j = tracks{i}(:,3)'
            dateref{j} = [dateref{j} i];
        end
    end
end