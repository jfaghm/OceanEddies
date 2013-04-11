import consts
from eddy import Eddy
from node import Node
from libc.math cimport sin, cos, acos, fabs

cdef double pi = 3.14159265

cdef double radians(double deg):
	return deg * pi / 180.0

cdef double get_max(double a, double b):
	if a > b:
		return a
	return b

cdef double get_min(double a, double b):
	if a < b:
		return a
	return b

cdef bint gate(old_node, new_node, double gate_dist):
	cdef double old_lon, new_lon, old_lat_rad, new_lat_rad, tmp, rad_dist, dist, adj_gate_dist
	old_lat_rad = radians(old_node.obj.lat)
	new_lat_rad = radians(new_node.obj.lat)
	old_lon = old_node.obj.lon
	new_lon = new_node.obj.lon
	tmp = sin(old_lat_rad) * sin(new_lat_rad) +   \
		cos(old_lat_rad) * cos(new_lat_rad) * \
		cos(radians(fabs(new_lon-old_lon)))
	rad_dist = acos(get_max(get_min(tmp, 1.0), -1.0)) # Force the number to strictly be within the domain
	dist = rad_dist * 6371.01 # km
	adj_gate_dist = gate_dist - fabs(old_node.obj.lat)
	if dist > adj_gate_dist:
		return False
	else:
		new_node.dist = dist
		return True

def gate_and_add(pnodes, new, gate_dist):
	for pnode in pnodes:
		if type(pnode.obj) is Eddy and gate(pnode, new, gate_dist):
			cpy = Node(new.obj)
			cpy.add_child(Node(consts.END))
			cpy.dist = new.dist
			pnode.add_child(cpy)
