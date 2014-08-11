#!/usr/bin/env python
import numpy as np

class Eddy(object):
	__slots__ = ('Stats', 'Lat', 'Lon', 'Amplitude', 'ThreshFound', 'SurfaceArea', 'Date',
		'Cyc', 'MeanGeoSpeed', 'DetectedBy')
	def __init__(self, stats, lat, lon, amp, thresh, surf_area, date, cyc, geo_speed,
		detectedby):
		self.Stats = new_stats_from_mat(stats)
		self.Lat = lat
		self.Lon = lon
		self.Amplitude = amp
		self.ThreshFound = thresh
		self.SurfaceArea = surf_area
		self.Date = date
		self.Cyc = cyc
		self.MeanGeoSpeed = geo_speed
		self.DetectedBy = detectedby

def new_stats_from_mat(stats):
	return np.array((stats.Area[0,0], stats.Extrema, stats.PixelIdxList.flatten(),
			stats.Intensity[0,0], stats.ConvexImage, stats.Solidity[0,0],
			stats.Extent[0,0], stats.Orientation[0,0], stats.MajorAxisLength[0,0],
			stats.MinorAxisLength[0,0]), dtype=[('Area', 'float64'),
				('Extrema', 'object'), ('PixelIdxList', 'object'),
				('Intensity', 'float64'), ('ConvexImage', 'object'),
				('Solidity', 'float64'), ('Extent', 'float64'),
				('Orientation', 'float64'), ('MajorAxisLength', 'float64'),
				('MinorAxisLength', 'float64')])
