#!/usr/bin/env python

class Eddy(object):
	__slots__ = ('lat', 'lon', 'surf_area', 'pixelidxlist', 'thresh', 'amp', 'id')
	def __init__(self, lat, lon, surf_area, pixelidxlist, thresh, amp):
		self.lat = lat
		self.lon = lon
		self.surf_area = surf_area
		self.pixelidxlist = pixelidxlist
		self.thresh = thresh
		self.amp = amp
