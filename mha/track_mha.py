#!/usr/bin/env python

import mht
import os
import sys

def usage():
	print 'Usage:  {} [srcdir] [srcpattern] [lookahead] [load data] [destmat]'.format(
		os.path.basename(__file__))
	print '    srdir:      Directory in which to find saved eddy frames'
	print '    srcpattern: Filename pattern used for eddies (ex. anticyc_ for'
	print '                anticyc_19921014.mat)'
	print '    lookahead:  Boolean value to run the scan with lookahead enabled [0 or 1]'
	print '    load data:  Path to pre-generated data. Use 0 to load no data.'
	print '    destmat:    Path to save mat-file(s). (should NOT end in .mat)'

if len(sys.argv) != 6:
	usage()
	sys.exit(1)

srcdir = sys.argv[1]
srcpattern = sys.argv[2]
do_look = sys.argv[3].lower() in ['1', 'yes', 'true']
if sys.argv[4].lower() in ['0', 'no', 'false']:
	load_path = None
else:
	load_path = sys.argv[4]
destmat = sys.argv[5]

if load_path is None:
	data = None
else:
	print 'Loading old data...'
	data = mht.load_tracks(load_path)
print 'Tracking...'
roots = mht.build_mht(mht.list_eddies(srcdir, srcpattern), do_lookahead=do_look, prev_data=data)
print 'Saving...'
mht.write_tracks(roots, destmat, mht.list_dates(srcdir, srcpattern))
