def identity(x):
	return x

def list_as_string(L):
	return ' '.join(map(str, L))

# Read a file straight into a list of strings
def read_straight(fname):
	f = open(fname, 'rt')
	ret = [x.strip() for x in f.readlines()[1:]]
	f.close()
	return ret

# Quick read if the data is one-per-line integers
def read_simple(fname, fMap=int):
	f = open(fname, 'rt')
	ret = [map(fMap, x.strip().split()) for x in f.readlines()[1:]]		
	f.close()
	return ret

# One-per-twoline with first line removable	
def read_simple_2(fname, fMap=int):
	f = open(fname, 'rt')
	ret = [map(fMap, x.strip().split()) for x in f.readlines()[2::2]]
	f.close()
	return ret

# Quick read T groups of N lines each (N given a line before as first element)
def read_N(fname, Nelt = 0, fMap=str, fOfN = lambda x: x, storeHead = False):
	f = open(fname, 'rt')
	L = [x.strip().split() for x in f.readlines()]
	f.close()
	T = int(L[0][0])
	output = []
	ln = 1
	for i in xrange(T):
		N = fOfN(int(L[ln][Nelt]))
		if storeHead:
			output.append([map(fMap, L[ln])] + [map(fMap, x) for x in L[ln+1:ln+N+1]])
		else:
			output.append([map(fMap, x) for x in L[ln+1:ln+N+1]])
		ln += (N+1)			
	return output
	
# Quick read T groups of lines given by some function of the first line among them
# Exact same default behaviour as read_N; but more flexible
def read_f(fname, fMapFn=lambda x: [str]*x[0], storeHead = False):
	f = open(fname, 'rt')
	L = [x.strip().split() for x in f.readlines()]
	f.close()
	T = int(L[0][0])
	output = []
	ln = 1
	for i in xrange(T):
		headerRow = map(int,L[ln])
		fMap = fMapFn(headerRow)
		N = len(fMap)
		if storeHead:
			output.append([headerRow] + [map(fMap[k], x) for k,x in enumerate(L[ln+1:ln+N+1])])
		else:
			output.append([map(fMap[k], x) for k,x in enumerate(L[ln+1:ln+N+1])])
		ln += (N+1)			
	return output
# e.g. L = read_f('C-test.in', lambda x: [str]*x[0] + [int]*x[1], lambda x: x[0]+x[1])

# READ_F with multi-line headers (also saves the headers if storeHead=True)
# This is the most general read function and can mimic (almost) the behaviour of all the others
def read_f_multi(fname, nlines_head=1,fMapFn=lambda x: [str]*x[0][0], fOfN = lambda x: x[0][0], storeHead=True):
	f = open(fname, 'rt')
	L = [x.strip().split() for x in f.readlines()]
	f.close()
	T = int(L[0][0])
	output = []
	ln = 1
	for i in xrange(T):
		head = [map(int, x) for x in L[ln:ln+nlines_head]]
		N = fOfN(head)
		fMap = fMapFn(head)
		if storeHead:
			output.append([head,[map(fMap[k], L[ln+nlines_head+k]) for k in xrange(N)]])
		else:
			output.append([map(fMap[k], L[ln+nlines_head+k]) for k in xrange(N)])
		ln += (N+nlines_head)
	return output

	
def read_fixed(fname, N, fMaps):
	f = open(fname, 'rt')
	L = [x.strip().split() for x in f.readlines()]
	f.close()
	T = int(L[0][0])
	ln = 1
	output = []
	for i in xrange(T):
		output.append([map(fMaps[k], L[ln+k]) for k in xrange(N)])
		ln+=N
	return output
	
# Quick one-item-per-line outputs	
def write_simple(fname, lst):
	f = open(fname, 'wt')
	f.writelines(['Case #' + str(i+1) + ': ' + str(lst[i]) + '\n' for i in xrange(len(lst))])	
	f.close()
	return

# Write a list of lists of strings
def write_slst(fname, strlst):
	lwrt = []
	for i, L in enumerate(strlst):
		lwrt.append('Case #' + str(i+1) + ':\n')
		lwrt.extend([' '.join(map(str, s)) + '\n' for s in L])

	f = open(fname, 'wt')
	f.writelines(lwrt)
	f.close()
	return
