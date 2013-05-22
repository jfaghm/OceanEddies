#!/usr/bin/env python

class Eddy(object):
	__slots__ = ('lat', 'lon', 'surf_area', 'pixelidxlist', 'thresh', 'amp', 'geo_speed', 'id')
	def __init__(self, lat, lon, surf_area, pixelidxlist, thresh, amp, geo_speed):
		self.lat = lat
		self.lon = lon
		self.surf_area = surf_area
		self.pixelidxlist = pixelidxlist
		self.thresh = thresh
		self.amp = amp
		self.geo_speed = geo_speed
