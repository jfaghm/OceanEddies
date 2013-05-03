#!/usr/bin/env python

import consts
import h5py
import math
import numpy as np
import scipy.io
import scipy.ndimage as ndimage
import skimage.morphology as morph
from eddy import *

if consts.DEBUG:
	import matplotlib.cm as cm
	import matplotlib.pyplot as plt

def trans_coords(shape, top, left, pairs):
	"""
	Changes 'pairs' in-place into coordinates that correspond to the ones in shape
	shape: dimensions of original matrix
	top, left: locations of the edges of the box (top is for x, left is for y)
	Does take into account if coordinates overflow in the x direction
	pairs: coordinate pairs to be manipulated

	NOTE: Expects coordinates as [y,x] not [x,y]!
	"""
	pairs[0,:] += top
	pairs[1,:] += left
	pairs[0,:] %= shape[0]

def trans_lonlat(londim, latdim, pairs):
	"""
	Returns an array containing [lon, lat] coords cooresponding to [y,x] in 'pairs'
	This correctly handles floating point coordinates

	Expects longitudinal values to go from 0 to 179.xx then -180 to -0.xx

	NOTE: Expects coordinates as corresponding to [lon, lat]!
	"""
	lonlat = np.zeros(pairs.shape, dtype=np.float64)
	for ii in range(pairs.shape[1]):
		if pairs[0,ii] < (londim / 2):
			lon = pairs[0,ii] * 180.0 / (londim/2.0)
		else:
			lon = ((pairs[0,ii]-(londim/2.0)) * 180.0 / (londim/2.0)) - 180.0
		lat = (pairs[1,ii] * 180.0 / (latdim-1)) - 90.0 # go from 0-latdim to 0-180 to -90 to 90
		lonlat[0,ii] = lon
		lonlat[1,ii] = lat
	return lonlat

def trans_linear(shape, pairs):
	"""
	Returns an array containing the linear values of the pixels in pairs.
	Linear values are indexed at 1 (for the sake of matlab compatibility)
	shape: dimensions of original matrix

	NOTE: Expects coordinates as [y,x] not [x,y]!
	"""
	pixels = np.zeros(pairs.shape[1], dtype=np.float64)
	pixels = pairs[0,:] * shape[1] + pairs[1,:] + 1
	return pixels

def find_centroid(canvas):
	# x refers to the second dim and y refers to to the first for consistency
	sum_x = 0.0
	sum_y = 0.0
	length = canvas.shape[1]
	for i in range(canvas.shape[1]):
		sum_x += canvas[0][i]
		sum_y += canvas[1][i]
	return (sum_x/length, sum_y/length)

def find_surfarea(areamap, pixels):
	"""
	pixels: [y1 y2 ... yN,x1 x2 ... xN] (where y corresponds to lon, x to lat)
	areamap: array providing area taken by a pixel at x (corresponding to lat)
	"""
	surfarea = 0
	for ii in range(pixels.shape[1]):
		surfarea += areamap[pixels[1,ii]]
	return surfarea

def threshold(ssh, areamap, lons, lats, cyc, spixels, base_th, index):
	"""
	Thresholds up (down) starting from base_th until it can no longer find more eddies. Returns
	[] is no more than 1 is found.

	ssh: ssh data for the current timestep
	areamap: provides areas for all of the latitudes possible with ssh
	lons: array for all lons (should have same length as ssh dim which corresponds to lons)
	lats: array for all lats (should have same length as ssh dim which corresponds to lats)
	cyc: Use CYCLONIC (1) or ANTICYC (-1)
	spixels: pixels that have been previously marked and wished to be thresholded
	base_th: base threshold to use (initial run does increase by THRESH_STEP)
	index: ID for the current eddy (used for debugging)
	"""
	ssh_32 = ssh.astype(np.float32)

	x = (spixels - 1) % ssh_32.shape[1]
	y = (spixels - 1) / ssh_32.shape[1]

	# Make bounding box and handle cases that go past 180 lon
	# left and right are for lat
	# top and bottom are for lon

	left = max(x.min()-2,0)
	right = min(x.max()+2, ssh_32.shape[1]-1)

	if y.max() == (ssh_32.shape[0]-1) and y.min() == 0:
		top = y[y > (ssh_32.shape[0]/2)].min()-2
		bottom = y[y < (ssh_32.shape[0]/2)].max()+2
	else:
		top = max(y.min()-2, 0)
		bottom = min(y.max()+2, ssh_32.shape[0]-1)

	if top > bottom:
		ssh_subset = np.zeros(((ssh_32.shape[0]-top)+bottom, right-left), dtype=np.float32)
		ssh_subset[0:ssh_32.shape[0]-top,:] = ssh_32[top:,left:right]
		ssh_subset[ssh_32.shape[0]-top:,:] = ssh_32[0:bottom, left:right]
	else:
		ssh_subset = ssh_32[top:bottom, left:right]

	initial = np.zeros(ssh_32.shape, dtype=np.float32)
	initial[y,x] = 1
	if top > bottom:
		initial_ss = np.zeros(ssh_subset.shape, dtype=np.float32)
		initial_ss[0:initial.shape[0]-top,:] = initial[top:,left:right]
		initial_ss[initial.shape[0]-top:,:] = initial[0:bottom, left:right]
	else:
		initial_ss = initial[top:bottom, left:right]
	keep = ndimage.binary_dilation(initial_ss)
	if cyc == -1:
		ssh_subset[keep == False] = base_th-1
	else:
		ssh_subset[keep == False] = base_th+1
	# Threshold until less eddies are found
	found_less = False
	ii = 1
	max_eddies = 1
	pixels = None
	centroids = None
	amplitudes = None

	disp_ssh = np.copy(ssh_subset)
	disp_ssh += 15
	disp_ssh /= 30
	disp_ssh[disp_ssh < 0] = 0
	disp_ssh[disp_ssh > 1] = 1
	# The ssh field has some extreme values, account for that
	while not found_less and ii < 100:
		if cyc == consts.ANTICYC:
			thresh_ssh = ssh_subset > base_th+consts.THRESH_STEP*ii
		else:
			thresh_ssh = ssh_subset < base_th-consts.THRESH_STEP*ii
		conncomp = morph.label(thresh_ssh, background=0)
		blob_count = conncomp.max()+1
		jj = 0
		while jj < blob_count:
			px_count = conncomp[conncomp == jj].shape[0]
			if px_count >= 4:
				jj += 1
				continue
			blob_count = blob_count - 1
			conncomp[conncomp == jj] = -1
			conncomp[conncomp > jj] -= 1
		if max_eddies < blob_count:
			max_eddies = blob_count
			thresh_found = base_th-cyc*consts.THRESH_STEP*ii
			pixels = np.zeros(blob_count, dtype=np.object)
			amplitudes = np.zeros(blob_count, dtype=np.object)
			centroids = np.zeros((2, blob_count), dtype=np.float64)
			if consts.DEBUG:
				plt.subplot(blob_count*100+211)
				plt.imshow(np.rot90(disp_ssh), interpolation='nearest', cmap=cm.gray)
				plt.subplot(blob_count*100+212)
				plt.imshow(np.rot90(initial_ss), interpolation='nearest', cmap=cm.gray)
			for jj in range(blob_count):
				pixels[jj] = np.array(np.nonzero(conncomp == jj))
				border_pixels = (conncomp == jj) - \
					ndimage.morphology.binary_erosion(conncomp == jj)
				meanperim = ssh_subset[border_pixels].mean()
				if cyc == -1:
					maxmin = ssh_subset[conncomp == jj].max()
				else:
					maxmin = ssh_subset[conncomp == jj].min()
				amplitudes[jj] = maxmin-meanperim
				centroids[:,jj] = find_centroid(pixels[jj])
				if consts.DEBUG:
					plt.subplot(blob_count*100 + 210 + jj + 3)
					plt.imshow(np.rot90(conncomp == jj),
						interpolation='nearest',
						cmap=cm.gray)
			if consts.DEBUG:
				print 'eddy:', index
				plt.show()
		elif max_eddies > blob_count:
			found_less = True
		ii += 1

	if pixels is None:
		return []

	raw_pixels = np.zeros(pixels.shape, dtype=np.object)
	surfareas = np.zeros(pixels.shape, dtype=np.float64)
	for i in range(pixels.shape[0]):
		trans_coords(ssh_32.shape, top, left, pixels[i])
		raw_pixels[i] = trans_linear(ssh_32.shape, pixels[i])
		surfareas[i] = find_surfarea(areamap, pixels[i])
	trans_coords(ssh_32.shape, top, left, centroids)
	lonlat_centroids = trans_lonlat(lons.shape[1], lats.shape[1], centroids)
	eddies = []
	for ii in range(lonlat_centroids.shape[1]):
		eddies.append(Eddy(lonlat_centroids[1,ii],
			lonlat_centroids[0,ii],
			surfareas[ii],
			raw_pixels[ii],
			thresh_found,
			amplitudes[ii]))
	return eddies
