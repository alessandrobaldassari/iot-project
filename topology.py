print "Topology script";
f = open('topology.txt', 'w')
for i in range(1,10):
	for j in range(1,10):
		if i != j:
			node1=str(i)
			node2=str(j)
			f.write(node1 + ' ' + node2 + ' ' + '-60.0\n')
f.close();

