function [ data ] = load_mha( path )
%LOAD_MHA Load MHA track data (without _fX extension or .mat)
    data = load([path '_f0']);
    for i = 1:(data.fileCount-1)
        t = load([path '_f' num2str(i)]);
        data.tracks = [data.tracks; t.tracks];
    end
end

