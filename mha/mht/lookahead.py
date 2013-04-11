import consts
from math import sin, cos, acos, fabs, radians
from node import Node

def add_lookahead_nodes(pnodes, eddies, closest_lst, gate_dist):
	"""If a previous (legitimate) node has only an END child, add a "missing" child"""
	for pnode in pnodes:
		if len(pnode.children) == 1 and not pnode.missing:
			missnode = Node(pnode.obj)
			missnode.missing = True
			missnode.dist = gate_dist
			missnode.add_child(Node(consts.END))
			pnode.add_child(missnode)
			old_lat_rad = radians(pnode.obj.lat)
			old_lon = pnode.obj.lon
			closest = (0,0,9999999999)
			for eddy in eddies:
				new_lat_rad = radians(eddy.lat)
				new_lon = eddy.lon
				tmp = sin(old_lat_rad) * sin(new_lat_rad) +   \
					cos(old_lat_rad) * cos(new_lat_rad) * \
					cos(radians(fabs(new_lon-old_lon)))
				# Force the number to strictly be within the domain
				rad_dist = acos(max(min(tmp, 1.0), -1.0))
				dist = rad_dist * 6371.01
				if dist < closest[2]:
					closest = (eddy.lat, eddy.lon, dist)
			closest_lst += [closest]
			pnode.closest = len(closest_lst)
