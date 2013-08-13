import consts
import mht
import numpy as np
import scipy.io
from collections import deque
from eddy import Eddy
from node import Node

def load_tracks(src):
	"""Load saved data. Returns a dict with all of the saved values (excluding start_date)."""
	mat = scipy.io.loadmat(src, struct_as_record=False)
	tracks = mat['tracks']
	info = mat['mhaInfo'][0,0]
	roots = [None]*tracks.shape[0]
	start_depth = info.EndDepth[0,0]
	prune_depth = info.PruneDepth[0,0]
	gate_dist = info.GateDist[0,0]
	for i in range(tracks.shape[0]):
		track = tracks[i,0]
		scores = info.Scores[i,0]
		missings = info.Missing[i,0].astype('bool')
		frames = track.Frames.flatten()
		parent = None
		for j in range(frames.shape[0]):
			eddy = Eddy(frames[j].Stats[0,0],
				frames[j].Lat[0,0],
				frames[j].Lon[0,0],
				frames[j].Amplitude[0,0],
				frames[j].ThreshFound[0,0],
				frames[j].SurfaceArea[0,0],
				frames[j].Date[0,0],
				frames[j].Cyc[0,0],
				frames[j].MeanGeoSpeed[0,0],
				frames[j].DetectedBy[0])
			node = Node(eddy)
			node.final = True
			node.base_depth = track.StartIndex[0,0]+j-1
			node.score = scores[j,0]
			node.missing = missings[j,0]
			if parent is None:
				roots[i] = node
			else:
				parent.set_child(node)
			parent = node
		parent.final = parent.base_depth < start_depth-1
		parent.add_child(Node(consts.END))
	return {'roots': roots,
		'start_depth': start_depth,
		'prune_depth': prune_depth,
		'gate_dist': gate_dist}

def export_tracks(roots, timesteps, prune_depth = 2):
	"""
	Will return eddies_tracks, scores_tracks, missings_tracks

	The non-eddy tracks are kept separate because they are mha-specific wheras all tracking
	algorithms should be saving tracks using the eddies_tracks format
	"""
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
	scores_tracks = np.zeros(len(all_tracks), dtype='object')
	missings_tracks = np.zeros(len(all_tracks), dtype='object')
	for i in range(len(all_tracks)):
		truelen = 0
		eddy_frames = np.zeros(len(all_tracks[i]), dtype=[('Stats', 'object'),
			('Lat', 'f8'), ('Lon', 'f8'), ('Amplitude', 'f8'),
			('ThreshFound', 'f8'), ('SurfaceArea', 'f8'), ('Date', 'f8'), ('Cyc', 'i2'),
			('MeanGeoSpeed', 'f8'), ('DetectedBy', 'object')])
		scores = np.zeros(len(all_tracks[i]), dtype='f8')
		missings = np.zeros(len(all_tracks[i]), dtype='b')
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
				scores[j] = all_tracks[i][j].score
				missings[j] = all_tracks[i][j].missing
				truelen = j
		eddy_frames = eddy_frames[:truelen+1]
		scores = scores[:truelen+1]
		missings = missings[:truelen+1]

		eddies_tracks[i]['StartDate'] = int(timesteps[all_tracks[i][0].base_depth])
		eddies_tracks[i]['StartIndex'] = all_tracks[i][0].base_depth + 1 # Matlab indexing
		eddies_tracks[i]['Length'] = len(eddy_frames)
		eddies_tracks[i]['Frames'] = eddy_frames
		scores_tracks[i] = scores
		missings_tracks[i] = missings
	return eddies_tracks, scores_tracks, missings_tracks

def write_tracks(roots, dest, timesteps, prune_depth = 2, gate_dist = 150):
	"""Write the confirmed portion of the tracks in roots to dest where timesteps is a tuple/list"""
	e_tracks, s_tracks, m_tracks = export_tracks(roots, timesteps, prune_depth)
	info = np.array((len(timesteps)-prune_depth, prune_depth, gate_dist, s_tracks, m_tracks),
		dtype=[('EndDepth', 'i4'), ('PruneDepth', 'i4'), ('GateDist', 'f8'),
		('Scores', 'object'), ('Missing', 'object')])
	scipy.io.savemat(dest,
		{'tracks': e_tracks,
		 'startDate': np.array(int(timesteps[0]), dtype='f8'),
		 'mhaInfo': info},
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
