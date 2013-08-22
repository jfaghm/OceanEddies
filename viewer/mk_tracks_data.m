function mk_tracks_data( varargin )
%MK_TRACKS_DATA Will save globa/tracks.mat. Arguments should be name,
%tracks. For example:
%  mk_tracks_data('Cyc LNN', lnn_cyc_tracks, 'Cyc MHA', mha_cyc_tracks)
    if nargin == 0 || mod(nargin,2) == 1
        error('Must pass arguments in as name, tracks');
    end
    
    tracks_cell = cell(nargin/2, 1);
    tracks_names = cell(nargin/2, 1);
    for i = 1:2:nargin
        tracks_names{int64((i+1)/2)} = varargin{i};
        tracks_cell{int64((i+1)/2)} = varargin{i+1};
    end
    
    save('global/tracks', 'tracks_names', 'tracks_cell');
end