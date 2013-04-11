#!/usr/bin/env python
import glob
import re

# Natural Sort from http://nedbatchelder.com/blog/200712/human_sorting.html
def __alphanum_key(s):
	""" Turn a string into a list of string and number chunks. "z23a" -> ["z", 23, "a"]"""
	return [ int(c) if c.isdigit() else c for c in re.split('([0-9]+)', s) ]

def __sort_nicely(l):
	""" Sort the given list in the way that humans expect."""
	l.sort(key=__alphanum_key)

def list_eddies(search_dir, cyc):
	"""
	Returns a list of pairs with each element being (date, path) for files that match the
	pattern a/b/(cyc)(date).mat

	search_dir: Directory in which to search for eddies
	cyc: Prefix for dataset ('anticyc_' or 'cyclonic_')
	"""
	if search_dir[-1] != "/":
		search_dir = search_dir + "/"
	pre_len = len(search_dir + cyc)
	paths = glob.glob(search_dir + cyc + '*.mat')
	__sort_nicely(paths)
	data = []
	for path in paths:
		data.append((path[pre_len:-4], path))
	return data

def list_dates(search_dir, cyc):
	"""
	Returns a list of dates for files that match the pattern a/b/(cyc)(date).mat

	search_dir: Directory in which to search for eddies
	cyc: Prefix for dataset ('anticyc_' or 'cyclonic_')
	"""
	if search_dir[-1] != "/":
		search_dir = search_dir + "/"
	pre_len = len(search_dir + cyc)
	paths = glob.glob(search_dir + cyc + '*.mat')
	__sort_nicely(paths)
	for i in range(len(paths)):
		paths[i] = paths[i][pre_len:-4]
	return paths
