#!/usr/bin/env python

import mht

prune_depth = 2

roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), mht.CYCLONIC,
	prune_depth=prune_depth, do_lookahead=True, gate_dist=150, prune_mode='parent')
mht.write_tracks(roots, 'cyclonic_tracks.mat',
	list_dates(eddies_path, 'eddies'), prune_depth, gate_dist=150)
