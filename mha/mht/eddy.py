#!/usr/bin/env python

class Eddy(object):
	__slots__ = ('Stats', 'Lat', 'Lon', 'Amplitude', 'ThreshFound', 'SurfaceArea', 'Date',
		'Cyc', 'MeanGeoSpeed', 'DetectedBy')
	def __init__(self, stats, lat, lon, amp, thresh, surf_area, date, cyc, geo_speed,
		detectedby):
		self.Stats = Stats.new_from_mat(stats)
		self.Lat = lat
		self.Lon = lon
		self.Amplitude = amp
		self.ThreshFound = thresh
		self.SurfaceArea = surf_area
		self.Date = date
		self.Cyc = cyc
		self.MeanGeoSpeed = geo_speed
		self.DetectedBy = detectedby

class Stats(object):
	__slots__ = ('Area', 'Extrema', 'PixelIdxList', 'Intensity', 'ConvexImage', 'BoundingBox',
		'Centroid', 'PixelList', 'Solidity', 'Extent', 'Orientation', 'MajorAxisLength',
		'MinorAxisLength')

	def __init__(self, area, extrema, pixelIdxList, intensity, convexImage, boundingBox,
		centroid, pixelList, solidity, extent, orientation, majorAxisLength,
		minorAxisLength):
		self.Area = area
		self.Extrema = extrema
		self.PixelIdxList = pixelIdxList
		self.Intensity = intensity
		self.ConvexImage = convexImage
		self.BoundingBox = boundingBox
		self.Centroid = centroid
		self.PixelList = pixelList
		self.Solidity = solidity
		self.Extent = extent
		self.Orientation = orientation
		self.MajorAxisLength = majorAxisLength
		self.MinorAxisLength = minorAxisLength

	@staticmethod
	def new_from_mat(stats):
		return Stats(stats.Area[0,0], stats.Extrema, stats.PixelIdxList[:,0],
			stats.Intensity[0,0], stats.ConvexImage, stats.BoundingBox[0,:],
			stats.Centroid[0,:], stats.PixelList, stats.Solidity[0,0],
			stats.Extent[0,0], stats.Orientation[0,0], stats.MajorAxisLength[0,0],
			stats.MinorAxisLength[0,0])
