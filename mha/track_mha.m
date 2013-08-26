function track_mha(srcdir, srcpattern, lookahead, load_data, destmat)
%TRACK_MHA Track eddies using Multiple Hypothesis Assignment
% srdir:      Directory in which to find saved eddy frames
% srcpattern: Filename pattern used for eddies (ex. anticyc_ for
%             anticyc_19921014.mat)
% lookahead:  Boolean value to run the scan with lookahead enabled [0 or 1]
% load data:  Path to pre-generated data. Use 0 to load no data.
% destmat:    Path to saved mat-file. (should end in .mat)
    if isa(load_data, 'numeric')
        load_data = '0';
    end
    
    mha_path = mfilename('fullpath');
    sep = strfind(mha_path, filesep());
    mha_path = [mha_path(1:sep(end)) 'track_mha.py'];
    
    cmd = sprintf('python "%s" "%s" "%s" %d "%s" "%s"', mha_path, ...
        srcdir, srcpattern, lookahead, load_data, destmat);
    status = system(cmd, '-echo');
    if status
        error('Failed to run MHA');
    end
end

