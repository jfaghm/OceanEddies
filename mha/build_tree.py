#!/usr/bin/env python

import mht

prune_depth = 2
ssh_data_path = 'global_ssh_180lon_1992_2012.mat'
quad_data_path = 'quadrangle_area_by_lat.mat'

roots, closest = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), mht.CYCLONIC, ssh_data_path,
	quad_data_path, prune_depth=prune_depth, do_lookahead=True, do_correction=True,
	gate_dist=150, prune_mode='parent')
mht.write_tracks(roots, 'cyclonic_tracks.mat',
	list_dates(eddies_path, 'eddies'), prune_depth, closest, gate_dist=150)
