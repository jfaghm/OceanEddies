% A sample script to compute eddies' shifts and scores

% Assume that ssh data were loaded into ssh variable as a 3D array
cyc_scores = nan(size(ssh));
cyc_shifts = nan(size(ssh));
for i = 1:size(ssh, 1)
    for j = 1:size(ssh, 2)
        [cyc_scores(i, j, :), cyc_shifts(i, j, :)] = getTimeSliceScore(ssh(i, j, :), 'cyc', true);
    end
end

ant_scores = nan(size(ssh));
ant_shifts = nan(size(ssh));
for i = 1:size(ssh, 1)
    for j = 1:size(ssh, 2)
        [ant_scores(i, j, :), ant_shifts(i, j, :)] = getTimeSliceScore(ssh(i, j, :), 'ant', true);
    end
end