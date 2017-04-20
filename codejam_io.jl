module codejam_io

export parse_int, parse_bigint, rep 
export read_straight, read_simple, read_simple_2, read_N, read_f, read_f_multi, read_fixed
export write_simple, write_slst, write_slst_h
export getFinFout, getFinFout_A, getFinFout_B, getFinFout_C, getFinFout_D, getFinFout_E, getFinFout_F

function parse_int(x)
	parse(Int, x)
end

function parse_bigint(x)
	parse(BigInt, x)
end

function rep(x, n)
	[x for i in 1:n]
end


# Read a file straight into a list of strings
function read_straight(fname::AbstractString)
	open(fname, "r") do f
        strip.(readlines(f))
    end
end

# Quick read if the data is one-per-line integers
function read_simple(fname::AbstractString, fMap=parse_int)
	open(fname, "r") do f  
		[fMap.(split(strip(x))) for x in readlines(f)[2:end]]
	end
end

# One-per-twoline with first line removable	
function read_simple_2(fname::AbstractString, fMap=parse_int)
	open(fname, "r") do f  
		[fMap.(split(strip(x))) for x in readlines(f)[3:2:end]]
	end
end

# Quick read T groups of N lines each (N given a line before as first element)
function read_N(fname::AbstractString; N_pos = 1, int_parser=parse_int, fMap=string, fOfN = (x->x), storeHead = false)
	L = open(fname, "r") do f
		split.(strip.(readlines(f)))
	end
	T = int_parser(L[1][1])
	output = []
	ln = 2
	for i in 1:T
		N = fOfN(int_parser(L[ln][N_pos]))
		if storeHead
			push!(output,[[fMap.(L[ln])], [fmap.(x) for x in L[ln+1:ln+N]]])
		else
			push!(output, [fMap.(x) for x in L[ln+1:ln+N]])
		end
		ln += (N+1)
	end			
	return output
end

# Quick read T groups of lines given by some function of the first line among them
# Exact same default behaviour as read_N; but more flexible
function read_f(fname::AbstractString, fMapFn=x->rep(string, x[1]); int_parser=parse_int, storeHead = false)
	L = open(fname, "r") do f
		split.(strip.(readlines(f)))
	end
	T = int_parser(L[1][1])
	output = []
	ln = 2
	for i in 1:T
		headerRow = int_parser.(L[ln])
		fMap = fMapFn(headerRow)
		N = length(fMap)
		if storeHead
			push!(output, [headerRow, [fMap[k].(x) for (k,x) in enumerate(L[ln+1:ln+N])]])
		else
			push!(output, [fMap[k].(x) for (k,x) in enumerate(L[ln+1:ln+N])])
		end
		ln += (N+1)
	end
	return output
end
# e.g. L = read_f('C-test.in', fMapFn=x->vcat(rep(string, x[1]), rep(parse_int,x[1]), rep(parse_int, x[2])))


# READ_F with multi-line headers (also saves the headers if storeHead=true)
# This is the most general read function and can mimic (almost) the behaviour of all the others
function read_f_multi(fname::AbstractString,fMapFn=x->rep(string,x[1][1]); nlines_head=1,int_parser=parse_int, storeHead=true)
	L = open(fname, "r") do f
		split.(strip.(readlines(f)))
	end
	T = int_parser(L[1][1])
	output = []
	ln = 2
	for i in 1:T
		head = [int_parser.(x) for x in L[ln:ln+nlines_head-1]]
		fMap = fMapFn(head)
		N = length(fMap)
		ln += nlines_head
		if storeHead
			push!(output, [head,[fMap[k].(x) for (k,x) in enumerate(L[ln:ln+N-1])]])
		else
			push!(output, [fMap[k].(x) for (k,x) in enumerate(L[ln:ln+N-1])])
		end
		ln += N
	end
	return output
end

# Read a sequence of inputs each one of which is a fixed number of lines	
function read_fixed(fname::AbstractString, fMaps; int_parser=parse_int)
	L = open(fname, "r") do f
		split.(strip.(readlines(f)))
	end
	T = int_parser(L[1][1])
	ln = 2
	N = length(fMaps)
	output = []
	for i in 1:T
		push!(output, [fMaps[k].(L[ln+k-1]) for k in 1:N])
		ln+=N
	end 
	return output
end 

# Quick one-item-per-line outputs	
function write_simple(fname, lst)
	f = open(fname, "w")
	for (i,elt) in enumerate(lst)
		println(f, "Case #$i: $(string(elt))")
	end 
	close(f)
end 

# Write a list of lists of strings
function write_slst(fname, strlst)
	f = open(fname, "w")
	for (i, L) in enumerate(strlst)
		println(f,"Case #$i:")
		for s in L
			println(f,join(string.(s), " "))
		end
	end
	close(f)
end 

# Write a list of lists of strings, but include a word/number on the first line with 'CASE'
function write_slst_h(fname, strlst)
	f = open(fname, "w")
	for (i, L) in enumerate(strlst)
		println(f,"Case #$i: $(L[1])")
		for s in L[2:end]
			println(f,join(string.(s), " "))
		end
	end
	close(f)
end

function getFinFout(v, default_in)
    if length(v) == 0
        fin = default_in
    else 
        fin = v[1]
    end
    if length(v) < 2
        fpos = search(fin, '.')
        if fpos == 0
            fin = default_in
        end
        fout = fin[1:fpos]*"out"
    else 
        fout = v[2]
    end

    return fin, fout
end

function getFinFout_A(v, default_in = "A-sample.in")
	return getFinFout(v, default_in)
end

function getFinFout_B(v, default_in = "B-sample.in")
	return getFinFout(v, default_in)
end

function getFinFout_C(v, default_in = "C-sample.in")
	return getFinFout(v, default_in)
end

function getFinFout_D(v, default_in = "D-sample.in")
	return getFinFout(v, default_in)
end

function getFinFout_E(v, default_in = "E-sample.in")
	return getFinFout(v, default_in)
end

function getFinFout_F(v, default_in = "F-sample.in")
	return getFinFout(v, default_in)
end

end