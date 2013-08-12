import consts
from node import Node

def add_lookahead_nodes(pnodes, gate_dist):
	"""If a previous (legitimate) node has only an END child, add a "missing" child"""
	for pnode in pnodes:
		if len(pnode.children) == 1 and not pnode.missing:
			missnode = Node(pnode.obj)
			missnode.missing = True
			missnode.dist = gate_dist
			missnode.add_child(Node(consts.END))
			pnode.add_child(missnode)
