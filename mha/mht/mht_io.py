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
		frames = track.Eddies[0,0]
		parent = None
		for j in range(track.Length[0,0]):
			eddy = Eddy(frames.Stats[j,0][0,0],
				frames.Lat[j,0],
				frames.Lon[j,0],
				frames.Amplitude[j,0],
				frames.ThreshFound[j,0],
				frames.SurfaceArea[j,0],
				frames.Date[j,0],
				frames.Cyc[j,0],
				frames.MeanGeoSpeed[j,0],
				frames.DetectedBy[j,0][0])
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
		('StartIndex', 'i4'), ('Length', 'u2'), ('Eddies', 'object')])
	scores_tracks = np.zeros(len(all_tracks), dtype='object')
	missings_tracks = np.zeros(len(all_tracks), dtype='object')
	for i in range(len(all_tracks)):
		truelen = 0
		stats = np.zeros(len(all_tracks[i]), dtype='object')
		lat = np.zeros(len(all_tracks[i]), dtype='f8')
		lon = np.zeros(len(all_tracks[i]), dtype='f8')
		amp = np.zeros(len(all_tracks[i]), dtype='f8')
		thf = np.zeros(len(all_tracks[i]), dtype='f8')
		sa = np.zeros(len(all_tracks[i]), dtype='f8')
		date = np.zeros(len(all_tracks[i]), dtype='f8')
		cyc = np.zeros(len(all_tracks[i]), dtype='i2')
		geo = np.zeros(len(all_tracks[i]), dtype='f8')
		dby = np.zeros(len(all_tracks[i]), dtype='object')
		scores = np.zeros(len(all_tracks[i]), dtype='f8')
		missings = np.zeros(len(all_tracks[i]), dtype='b')
		for j in range(len(all_tracks[i])):
			if type(all_tracks[i][j].obj) is Eddy:
				stats[j] = all_tracks[i][j].obj.Stats
				lat[j] = all_tracks[i][j].obj.Lat
				lon[j] = all_tracks[i][j].obj.Lon
				amp[j] = all_tracks[i][j].obj.Amplitude
				thf[j] = all_tracks[i][j].obj.ThreshFound
				sa[j] = all_tracks[i][j].obj.SurfaceArea
				date[j] = all_tracks[i][j].obj.Date
				cyc[j] = all_tracks[i][j].obj.Cyc
				geo[j] = all_tracks[i][j].obj.MeanGeoSpeed
				dby[j] = all_tracks[i][j].obj.DetectedBy
				scores[j] = all_tracks[i][j].score
				missings[j] = all_tracks[i][j].missing
				truelen = j
		stats = stats[:truelen+1]
		lat = lat[:truelen+1]
		lon = lon[:truelen+1]
		amp = amp[:truelen+1]
		thf = thf[:truelen+1]
		sa = sa[:truelen+1]
		date = date[:truelen+1]
		cyc = cyc[:truelen+1]
		geo = geo[:truelen+1]
		dby = dby[:truelen+1]
		eddy_frames = np.array((stats, lat, lon, amp, thf, sa, date, cyc, geo, dby), dtype=[
			('Stats', 'object'), ('Lat', 'object'), ('Lon', 'object'),
			('Amplitude', 'object'), ('ThreshFound', 'object'),
			('SurfaceArea', 'object'), ('Date', 'object'), ('Cyc', 'object'),
			('MeanGeoSpeed', 'object'), ('DetectedBy', 'object')])
		scores = scores[:truelen+1]
		missings = missings[:truelen+1]

		eddies_tracks[i]['StartDate'] = int(timesteps[all_tracks[i][0].base_depth])
		eddies_tracks[i]['StartIndex'] = all_tracks[i][0].base_depth + 1 # Matlab indexing
		eddies_tracks[i]['Length'] = len(lat)
		eddies_tracks[i]['Eddies'] = eddy_frames
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
		do_compression=False)

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
