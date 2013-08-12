#!/usr/bin/env python

import consts
import lookahead
import mht_io as io
import numpy as np
import scipy.io
import time
from collections import deque
from eddy import *
from mht_c import *
from node import *

def score(path, gate_dist):
	"""
	Scores a tuple/list of nodes that form a track

	path: track to score
	"""
	sum = 0
	# Each path is really two, one that terminates, and one that continues
	# For now, don't reward termination
	for i in range(len(path))[1:-1]:
#		cos_angle = 1
#		if i > 1:
#			u = (path[i-1].obj.Lon - path[i-2].obj.Lon, \
#				path[i-1].obj.Lat - path[i-2].obj.Lat)
#			v = (path[i].obj.Lon - path[i-1].obj.Lon, \
#				path[i].obj.Lat - path[i-1].obj.Lat)
#			cos_angle = (u[0]*v[0] + u[1]*v[1]) /   \
#				(math.sqrt(u[0]**2 + u[1]**2) * \
#				math.sqrt(v[0]**2 + v[1]**2))
		sum += ( gate_dist - path[i].dist ) #* (1 - cos_angle) )
	return sum

def get_eddy_instances(parents, root_nodes, gate_dist):
	"""
	Searches nodes for eddies and returns ([dict with eddy instances], [dict with child scores and parents])

	parents: list of parent nodes to search
	root_nodes: list of nodes that are roots (NOTE: expects these to already be filtered for depth) (default False)
	"""
	snodes = []
	e_instances = dict()
	child_score = dict()
	for parent in parents:
		for child in parent.children:
			if is_term(child):
				continue
			child.score = parent.score + max(score(hyp, gate_dist) for hyp in child.tracks())
			child_score[child] = (child.score, parent)
			if child.obj in e_instances:
				e_instances[child.obj].append(child)
			else:
				e_instances[child.obj] = [child]
	for node in root_nodes:
		node.score = max(score(hyp, gate_dist) for hyp in node.tracks())
		child_score[node] = (node.score, None)
		if node.obj in e_instances:
			e_instances[node.obj].append(node)
		else:
			e_instances[node.obj] = [node]
	return (e_instances, child_score)

def prune(roots, depth, gate_dist):
	def set_score(node):
		node.score = max(score(hyp, gate_dist) for hyp in node.tracks())
	if depth == 0:
		map(set_score, roots)
		## We don't have any conflicts at depth = 0 (yet)
		# Tracks ARE in order here so we can be smart when removing them
	else:
		parents = get_nodes_at_depth(roots, depth - 1)
		parentless = (node for node in roots if node.base_depth == depth)

		e_instances, child_score = get_eddy_instances(parents, parentless, gate_dist)

		if consts.DEBUG:
			io.fmt_print_with_no_root(e_instances, child_score)

		for instances in e_instances.values():
			big = max(child_score[child] + (child,) for child in instances)
			if big[1] is not None:
				for child in big[1].children:
					if child is not big[2] and child.obj in e_instances.keys():
						e_instances[child.obj].remove(child)
				big[1].set_child(big[2])
			for child in instances:
				if child is not big[2]:
					if child_score[child][1] is None:
						roots.remove(child)
					else:
						child_score[child][1].remove_child(child)

def prune_parent(roots, depth, gate_dist):
	def set_score(node):
		node.score = max(score(hyp, gate_dist) for hyp in node.tracks())
	if depth == 0:
		map(set_score, roots)
		## We don't have any conflicts at depth = 0 (yet)
		# Tracks ARE in order here so we can be smart when removing them
	else:
		parents = get_nodes_at_depth(roots, depth - 1)
		parentless = (node for node in roots if node.base_depth == depth)

		e_instances, child_score = get_eddy_instances(parents, parentless, gate_dist)

		if consts.DEBUG:
			io.fmt_print_with_no_root(e_instances, child_score)

		for parent in parents:
			if len(parent.children) > 1:
				big = max([(score(hyp, gate_dist), hyp[1]) for hyp in parent.tracks()])
				parent.set_child(big[1])
				if big[1].obj in e_instances.keys():
					for child in e_instances[big[1].obj]:
						if child is not big[1]:
							if child_score[child][1] is None:
								roots.remove(child)
							elif not child_score[child][1].final:
								child_score[child][1].remove_child(child)

def mk_node_and_add(eddy, depth, pnodes, roots, gate_dist):
	enode = Node(eddy)
	enode.add_child(Node(consts.END))
	gate_and_add(pnodes, enode, gate_dist)
	enode.base_depth = depth
	enode.dist = 0 # This was set during gate_and_add()'s calls to gate()
	roots.append(enode)

def build_mht(eddies_data,
	prune_depth = 2,
	within_bounds = lambda x: True,
	do_lookahead = True,
	gate_dist = 150,
	prev_data = None,
	prune_mode = 'parent'):
	"""
	Build the multi-hypothesis tree. Returns roots as an iterator.

	eddies_data: iterator of tuples which are (date, path)
	prune_depth: depth at which to begin pruning (index of 0)
	within_bounds: function to check whether an eddy should be included in the results
	do_lookahead: Boolean value whether or not to allow eddies to disappear for one timestep
	prev_data: Load previously computed data. Expects a dict with keys roots,
	           start_depth (depth at which this instance should start), prune_depth, gate_dist.
	prune_mode: What method should be used for pruning. Use 'child' for pruning by finding the
	            ideal parent for a given node. Use 'parent' for pruning by finding the ideal
	            eddies from the current (for pruning) timestep for a given parent.
	"""

	roots = []
	depth = 0

	if prev_data is not None:
		roots = prev_data['roots']
		depth = prev_data['start_depth']
		prune_depth = prev_data['prune_depth']
		gate_dist = prev_data['gate_dist']

	if depth >= len(eddies_data):
		return roots

	for dataset in eddies_data[depth:]:
		start_time = time.mktime(time.localtime())
		print dataset[0]
		mat = scipy.io.loadmat(dataset[1], struct_as_record=False)
		eddies = mat['eddies'][0]
		pnodes = get_nodes_at_depth(roots, depth - 1)
		for i in range(len(eddies)):
			eddy = Eddy(eddies[i].Stats[0,0],
				eddies[i].Lat[0,0],
				eddies[i].Lon[0,0],
				eddies[i].Amplitude[0,0],
				eddies[i].ThreshFound[0,0],
				eddies[i].SurfaceArea[0,0],
				eddies[i].Date[0,0],
				eddies[i].Cyc[0,0],
				eddies[i].MeanGeoSpeed[0,0],
				eddies[i].DetectedBy[0])
			if not within_bounds(eddy):
				continue
			mk_node_and_add(eddy, depth, pnodes, roots, gate_dist)

		if do_lookahead:
			lookahead.add_lookahead_nodes(pnodes, gate_dist)

		if depth >= prune_depth:
			if prune_mode == 'parent':
				prune_parent(roots, depth-prune_depth, gate_dist)
			else:
				prune(roots, depth-prune_depth, gate_dist)
		depth += 1
		print 'time:', time.mktime(time.localtime())-start_time

	return roots
