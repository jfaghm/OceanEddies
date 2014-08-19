function [ combined ] = get_combined_eddy_frames(bu, es, ssh)
%GET_COMBINED_EDDY_FRAMES Returns a matrix with BU frames + ES-only frames,
%ES-Only frames do not contain ANY overlap with BU frames
    bu_map = false(size(ssh, 1), size(ssh, 2));

    for i = 1:length(bu)
        bu_map(bu(i).Stats.PixelIdxList) = true;
    end

    es_only = false(size(es));
    for i = 1:length(es)
        es_only(i) = ~any(bu_map(es(i).Stats.PixelIdxList));
    end
    
    combined = [bu es(es_only)];
end


