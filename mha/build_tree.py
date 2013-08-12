#!/usr/bin/env python

import mht

eddies_path = '/path/to/eddyscan/out'

roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), do_lookahead=True)
mht.write_tracks(roots, 'cyclonic_tracks.mat', mht.list_dates(eddies_path, 'eddies'))
