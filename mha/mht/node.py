#!/usr/bin/env python

import consts
from collections import deque

class Node(object):
	def __init__(self, obj):
		self.obj = obj
		self.children = []
		self.base_depth = 0
		self.final = False
		self.score = 0
		self.dist = 0
		self.missing = False

	def add_child(self, child):
		self.children.append(child)

	def remove_child(self, child):
		self.children.remove(child)

	def add_children(self, children):
		self.children += children

	def set_child(self, child):
		"""Sets the final child value effectively turning the tree into a chain"""
		self.children = [child]
		self.final = True

	def tracks(self):
		finals = []
		tracks = deque([[self]])
		while tracks:
			ctrack = tracks.popleft()
			if ctrack[-1].children == []:
				finals.append(ctrack)
				continue
			for child in ctrack[-1].children:
				tracks.append(ctrack + [child])
		return finals

def is_term(node):
	if node.obj == consts.END:
		return True
	else:
		return False

def get_nodes_at_depth(roots, depth):
	all_nodes = []
	for root in roots:
		nodes = []
		cnodes = deque([(root, root.base_depth)])
		while cnodes:
			cnode = cnodes.popleft()
			if cnode[1] > depth:
				continue
			elif cnode[1] == depth:
				nodes.append(cnode[0])
			else:
				for child in cnode[0].children:
					cnodes.append((child, cnode[1]+1))
		all_nodes += nodes
	return all_nodes
