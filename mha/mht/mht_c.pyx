import consts
from eddy import Eddy
from node import Node
from libc.math cimport sin, cos, acos, asin, sqrt, fabs

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

# Uses http://en.wikipedia.org/wiki/Haversine_formula
cdef double get_dist(double lon1, double lat1, double lon2, double lat2):
	cdef double tmp, rad_dist, dlon
	if (lat1 == lat2) and (lon1 == lon2):
		return 0
	lat1 = radians(lat1)
	lat2 = radians(lat2)
	dlon = radians(fabs(lon2-lon1))
	tmp = sqrt(sin((lat2-lat1)/2)**2 + cos(lat1)*cos(lat2)*sin(dlon/2)**2)
	rad_dist = 2*asin(get_max(get_min(tmp, 1.0), -1.0)) # Force the number to be within the domain
	return rad_dist * 6371.01 # km

def geodesic_dist(lon1, lat1, lon2, lat2):
	return get_dist(lon1, lat1, lon2, lat2)

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
