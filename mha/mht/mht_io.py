import mht
import numpy as np
import scipy.io
from collections import deque
from eddy import Eddy
from node import Node

def load_tracks(src, timesteps):
	"""Load saved data. Returns a dict with all of the saved values (excluding start_date)."""
	mat = scipy.io.loadmat(src, struct_as_record=False)
	tracks = mat['tracks']
	roots = [None]*tracks.shape[0]
	for j in range(tracks.shape[0]):
		track = tracks[j,0]
		parent = None
		for i in range(track.shape[0]):
			pixels = track[i,10:]
			pixels = pixels[pixels > -1]
			eddy = Eddy(track[i,0], track[i,1], track[i,5], pixels, track[i,8],
				track[i,6], track[i,9])
			node = Node(eddy)
			node.final = True
			node.base_depth = int(track[i,2]-1)
			node.score = track[i,3]
			node.missing = bool(track[i,7])
			if parent is None:
				roots[j] = node
			else:
				parent.set_child(node)
			parent = node
	start_depth = mat['end_depth'][0,0]
	prune_depth = mat['prune_depth'][0,0]
	gate_dist = mat['gate_dist'][0,0]
	return {'roots':roots,
		'start_depth':start_depth,
		'prune_depth':prune_depth,
		'gate_dist':gate_dist}

def export_tracks(roots, timesteps, prune_depth):
	all_tracks = deque()
	for root in roots:
		for track in root.tracks():
			end = len(timesteps)-prune_depth-track[0].base_depth
			if end <= 0:
				continue
			sure_track = track[:end]
			all_tracks.append(tuple(sure_track))

	all_tracks = tuple(set(all_tracks))
	
	eddies_tracks = np.zeros(len(all_tracks), dtype=[('StartDate', 'i4'),
		('StartIndex', 'i4'), ('Length', 'u2'), ('Frames', 'object')])
	for i in range(len(all_tracks)):
		truelen = 0
		eddy_frames = np.zeros(len(all_tracks[i]), dtype=[('Stats', 'object'),
			('Lat', 'f8'), ('Lon', 'f8'), ('Amplitude', 'f8'),
			('ThreshFound', 'f8'), ('SurfaceArea', 'f8'), ('Date', 'f8'), ('Cyc', 'i2'),
			('MeanGeoSpeed', 'f8'), ('DetectedBy', 'object')])
		for j in range(len(all_tracks[i])):
			if type(all_tracks[i][j].obj) is Eddy:
				eddy_frames[j]['Stats'] = all_tracks[i][j].obj.Stats
				eddy_frames[j]['Lat'] = all_tracks[i][j].obj.Lat
				eddy_frames[j]['Lon'] = all_tracks[i][j].obj.Lon
				eddy_frames[j]['Amplitude'] = all_tracks[i][j].obj.Amplitude
				eddy_frames[j]['ThreshFound'] = all_tracks[i][j].obj.ThreshFound
				eddy_frames[j]['SurfaceArea'] = all_tracks[i][j].obj.SurfaceArea
				eddy_frames[j]['Date'] = all_tracks[i][j].obj.Date
				eddy_frames[j]['Cyc'] = all_tracks[i][j].obj.Cyc
				eddy_frames[j]['MeanGeoSpeed'] = all_tracks[i][j].obj.MeanGeoSpeed
				eddy_frames[j]['DetectedBy'] = all_tracks[i][j].obj.DetectedBy
				truelen = j
		eddy_frames = eddy_frames[:truelen+1]

		eddies_tracks[i]['StartDate'] = int(timesteps[all_tracks[i][0].base_depth])
		eddies_tracks[i]['StartIndex'] = all_tracks[i][0].base_depth + 1 # Matlab indexing
		eddies_tracks[i]['Length'] = len(eddy_frames)
		eddies_tracks[i]['Frames'] = eddy_frames
	return eddies_tracks

def write_tracks(roots, dest, timesteps, prune_depth, gate_dist = 150):
	"""Write the confirmed portion of the tracks in roots to dest where timesteps is a tuple/list"""
	eddies_tracks = export_tracks(roots, timesteps, prune_depth)
	scipy.io.savemat(dest,
		{'tracks': eddies_tracks,
		 'start_date': np.array(int(timesteps[0]), dtype=np.int),
		 'end_depth': np.array(len(timesteps)-prune_depth, dtype=np.int),
		 'prune_depth': np.array(prune_depth, dtype=np.int),
		 'gate_dist': np.array(gate_dist, dtype=np.float64)},
		appendmat=False,
		format='5',
		oned_as='column',
		do_compression=True)

def fmt_print_with_no_root(e_instances, child_score):
	"""Prints out eddies that don't have an instance that starts a new track"""
	for eddy, instances in e_instances.items():
		has_root = False
		for instance in instances:
			if child_score[instance][1] is None:
				has_root = True
		if not has_root:
			print eddy
			for instance in instances:
				print ' ------'
				for child in instance.children:
					print ' ->', child.obj
