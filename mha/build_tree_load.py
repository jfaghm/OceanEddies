#!/usr/bin/env python
# Use a script formatted like this to load old data and use it when computing tracks for an
# extended dataset.
# NOTE: All old frame files must exist (or at least placeholders must)

import mht

eddies_path = '/path/to/eddyscan/out'

print 'Loading old data...'
data = mht.load_tracks('cyclonic_tracks.mat')
print 'Tracking...'
roots = mht.build_mht(mht.list_eddies(eddies_path, 'eddies'), do_lookahead=True, prev_data=data)
print 'Saving...'
mht.write_tracks(roots, 'cyclonic_tracks.mat', mht.list_dates(eddies_path, 'eddies'))
