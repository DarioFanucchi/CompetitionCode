##################################################################
# READ TROUBLESOME FILES WITH TOO MUCH WHITESPACE IN PLACES
##################################################################
read_and_unspace() = strip(replace(readline(), r"\s+", " "))
read_ints() = [parse(Int, x) for x in split(read_and_unspace(), " ")]

##################################################################
# PRIMES AND DIVISORS
##################################################################

# prime sieve with prime factors dictionary
function primesAndFactors(n::Int)
    sieve = [true for i in 1:n]
    sieve[1] = false
    prime_factors = [Dict{Int,Int}() for i in 1:n]
    for i in 2:n
        if sieve[i]
            prime_factors[i][i] = 1
            for j in (2i):i:n
                sieve[j] = false
                mul = 1
                k = j/i
                while k%i == 0
                    mul += 1
                    k/=i
                end 
                prime_factors[j][i] = mul
            end
        end
    end
    primes = [i for i in 1:n if sieve[i]]
    return (sieve, primes, prime_factors)
end

# get the divisors of a number given its prime factorisation
function divisors_from_factors(factors::Dict{Int,Int})
    if length(factors)==0
        return Array{Int,1}()
    end
    ndivisors = prod(1+collect(values(factors)))

    bases = collect(keys(factors))
    exponents = [factors[x] for x in bases]
    divisors = zeros(Int, ndivisors)
    offset = 1
    N = length(bases)

    function enumerate_divs(cur_idx, cur_val)
        if cur_idx > N
            divisors[offset] = cur_val
            offset+=1
        else
            mul = cur_val
            for i in 0:exponents[cur_idx]
                enumerate_divs(cur_idx+1, mul)
                mul *= bases[cur_idx]
            end
        end
    end
    enumerate_divs(1, 1)
    return divisors
end

##################################################################
# Least unused natural number structure
##################################################################
type least_unused
    start_pos::Int
    cur_pos::Int 
    unused::Base.Collections.PriorityQueue{Int, Int, Base.Order.ForwardOrdering}
    least_unused(sp::Int=0) = new(sp, sp, Base.Collections.PriorityQueue{Int, Int, Base.Order.ForwardOrdering}())
end

function unuse!(l::least_unused, val::Int)
    l.unused[val] = val
end

function use!(l::least_unused)
    if(isempty(l.unused))
        l.cur_pos += 1
        return l.cur_pos
    else
        return Base.Collections.dequeue!(l.unused)
    end
end

function use!(l::least_unused, n::Int)
    if n > l.cur_pos
        for k in (l.cur_pos+1):(n-1)
            unuse!(l, k)
        end
        l.cur_pos = n
    else
        l.unused[n] = -1
        Base.Collections.dequeue!(l.unused)
    end
end

function top(l::least_unused)
    if(isempty(l.unused))
        return l.cur_pos + 1
    else 
        return Base.Collections.peek(l.unused)[1]
    end
end


##################################################################
# Interval tree to aggregate any function over an interval 
##################################################################

type itreeNode{T<:Number}
    value::T
    pos::Int # position at which the value is obtained
    left::Int 
    right::Int
    children::Vector{itreeNode{T}}
    itreeNode() = new(0, 0, 0, 0, Vector{itreeNode{T}}())
    itreeNode(v::T, p::Int, l::Int, r::Int) = new(v,p,l,r,Vector{itreeNode{T}}())
    itreeNode(v::T, p::Int, l::Int, r::Int, lc::itreeNode{T}, rc::itreeNode{T}) = new(v,p, l, r, [lc,rc])
    itreeNode(v::T, p::Int, l::Int, r::Int, ch::Vector{itreeNode{T}}) = new(v,p,l,r,ch)
end
itreeNode() = itreeNode{Int}()

function create_itree_closure{T}(v::Vector{T}, agg::Function, isleft::Function)
    function create_interval_tree(l::Int, r::Int)
        if l == r
            return itreeNode{T}(v[l], l, l, r)
        else 
            mid_l = (l+r)>>1
            mid_r = mid_l + 1
            lhs = create_interval_tree(l, mid_l)
            rhs = create_interval_tree(mid_r, r)
            val = agg(lhs.value, rhs.value)
            left_side = isleft(lhs.value, rhs.value)
            pos = 0
            if left_side 
                pos = lhs.pos 
            else
                pos = rhs.pos
            end
            return itreeNode{T}(val, pos, l, r, lhs, rhs)
        end
    end
    return create_interval_tree
end

type itree{T}
    fn::Function
    isleft::Function
    x::Vector{T}
    root::itreeNode{T}
    default::T
    itree(v::Vector{T}, fn::Function, def::T) = new(fn, (x,y)->true, v, create_itree_closure(v,fn, (x,y)->true)(1, length(v)), def)
    itree(v::Vector{T}, fn::Function, leftfn::Function, def::T) = new(fn, leftfn, v, create_itree_closure(v,fn, leftfn)(1, length(v)), def)
end
itree(v::Vector{Int}, fn::Function, leftfn::Function, def::Int) = itree{Int}(v,fn,leftfn,def)
mintree(v::Vector{Int}) = itree{Int}(v, min, (x,y)->(x<=y), maximum(v)+1)
maxtree(v::Vector{Int}) = itree{Int}(v, max, (x,y)->(x>=y), minimum(v)-1)


# Query an itree on an interval
function query{T}(it::itree{T}, left::Int, right::Int)
    function qry_inner(cur::itreeNode{T}, l::Int, r::Int)
        if r < cur.left || l > cur.right
            return it.default
        elseif l <= cur.left && cur.right <= r
            return cur.value
        else
            mid_l = cur.children[1].right
            mid_r = cur.children[2].left
            if r <= mid_l
                return qry_inner(cur.children[1], l, r) 
            elseif l >= mid_r
                return qry_inner(cur.children[2], l, r) 
            else  
                return it.fn(qry_inner(cur.children[1], l, min(r,mid_l)), qry_inner(cur.children[2], max(mid_r, l), r))
            end
        end
    end
    return qry_inner(it.root, left, right)
end

# Query an itree on an interval
function query_pos{T}(it::itree{T}, left::Int, right::Int)
    function qry_inner(cur::itreeNode{T}, l::Int, r::Int)
        if r < cur.left || l > cur.right
            return it.default
        elseif l <= cur.left && cur.right <= r
            return (cur.pos, cur.value)
        else
            mid_l = cur.children[1].right
            mid_r = cur.children[2].left
            if r <= mid_l
                return qry_inner(cur.children[1], l, r) 
            elseif l >= mid_r
                return qry_inner(cur.children[2], l, r) 
            else  
                x = qry_inner(cur.children[1], l, min(r,mid_l))
                y = qry_inner(cur.children[2], max(mid_r, l), r)
                if it.isleft(x[2],y[2])
                    return (x[1], it.fn(x[2],y[2]))
                else
                    return (y[1], it.fn(x[2], y[2])) 
                end
            end
        end
    end
    return qry_inner(it.root, left, right)[1]
end


##################################################################
# next smaller index algorithm in linear time
##################################################################

# Find the index of the next number in an array to be smaller than
# each element and to the right
function get_next_smaller(A::Vector{Int}, default_elt::Int=0)
    n = length(A)
    unmatched = Base.Collections.PriorityQueue{Int, Int, Base.Order.ForwardOrdering}()
    next_smaller = [default_elt for i in 1:n]

    for i in 1:n
        while !isempty(unmatched)
            (idx, val) = Base.Collections.peek(unmatched) 
            val = -val
            if val > A[i]
                next_smaller[idx] = i
                Base.Collections.dequeue!(unmatched)
            else 
                break 
            end            
        end
        unmatched[i] = -A[i]
    end
    return next_smaller
end


##################################################################
# Strongly connected components
##################################################################

# 1-indexed directed adjacency set graph
type directed_adjset_graph
    n::Int
    adj::Array{Set{Int},1}
    directed_adjset_graph(n_vert::Int) = new(n_vert, [Set{Int}() for i in 1:n_vert])
end

function add_edge!(G::directed_adjset_graph, u::Int, v::Int)
    if u == G.n+1 || v == G.n + 1
        push!(G.adj, Set{Int}())
        G.n += 1
    end

    push!(G.adj[u], v)
end

function is_edge(G::directed_adjset_graph, u::Int, v::Int)
    return (v in G.adj[u])
end


# Tarjan's algorithm to compute strongly connected components & condensation
function tarjan(G::directed_adjset_graph)
    index = 0
    dfs_stack   = Vector{Tuple}()
    ddone       = falses(G.n)
    ddescending = trues(G.n)
    S        = Vector{Int}()
    vindex   = zeros(Int, G.n)
    vlowlink = zeros(Int, G.n) 
    visited  = falses(G.n)
    onStack  = falses(G.n)
    SCC_map  = zeros(Int, G.n)
    cur_SCC  = 0

    for vertex in 1:G.n
        if !visited[vertex]
            push!(dfs_stack, (vertex, vertex))
            while(!isempty(dfs_stack))
                v_prev,v = dfs_stack[end]
                if ddone[v]
                    pop!(dfs_stack)
                    continue
                end

                visited[v] = true

                # Set the depth index for v to the smallest unused index
                if ddescending[v]
                    ddescending[v] = false

                    vindex[v] = index
                    vlowlink[v] = index
                    index += 1
                    push!(S, v)
                    onStack[v] = true

                    for w in G.adj[v]
                        if !visited[w]
                            push!(dfs_stack, (v,w))
                        elseif onStack[w] 
                            vlowlink[v] = min(vlowlink[v], vindex[w])
                        end
                    end                    
                else 
                    v_prev, v = pop!(dfs_stack)
                    ddone[v] = true 
                    vlowlink[v_prev] = min(vlowlink[v_prev], vlowlink[v])

                    # If v is a root node, pop the stack and generate an SCC
                    if vlowlink[v] == vindex[v]
                        cur_SCC += 1
                        while !isempty(S)
                            w = pop!(S)
                            onStack[w] = false 
                            SCC_map[w] = cur_SCC
                            if w == v 
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    condensation = directed_adjset_graph(cur_SCC)
    for i in 1:G.n
        for j in G.adj[i]
            if SCC_map[i] != SCC_map[j]
               add_edge!(condensation, SCC_map[i], SCC_map[j])
           end
        end
    end

    return (SCC_map, condensation)
end

#################################################################
#          Connected components                                 #
#################################################################

# 1-indexed undirected adjacency set graph
type adjset_graph
    n::Int
    adj::Array{Set{Int},1}
    adjset_graph(n_vert::Int) = new(n_vert, [Set{Int}() for i in 1:n_vert])
end

function add_edge!(G::adjset_graph, u::Int, v::Int)
    if u == G.n+1 || v == G.n + 1
        push!(G.adj, Set{Int}())
        G.n += 1
    end

    push!(G.adj[u], v)
    push!(G.adj[v], u)
end

function is_edge(G::adjset_graph, u::Int, v::Int)
    return (v in G.adj[u])
end

immutable Edge 
    u::Integer
    v::Integer
end

# Simple DFS (can be done much more efficiently with union-find)
function get_components(g::adjset_graph)
    components = zeros(Int, g.n)
    v0 = 1
    cpt = 1
    while v0 <= g.n 
        if components[v0] == 0
            S = [v0]
            while !isempty(S)
                v = pop!(S)
                components[v] = cpt
                for w in g.adj[v]
                    if components[w] == 0
                        push!(S, w)
                    end
                end
            end
            cpt += 1
        end
        v0 += 1
    end 
    return components
end

    
#################################################################
#          Biconnected components (adapted from LightGraphs.jl) #
#################################################################

type Biconnections
    low::Vector{Int}
    depth::Vector{Int}
    stack::Vector{Edge}
    biconnected_comps::Vector{Vector{Edge}}
    is_articulation::Vector{Bool}
    id::Int
end

function Biconnections(g::adjset_graph)
    n = g.n
    return Biconnections(zeros(Int, n), zeros(Int, n), Vector{Edge}(), Vector{Vector{Edge}}(), falses(n),0)
end


# Biconnected component dfs
function bc_dfs!(g::adjset_graph, state::Biconnections, u::Integer, v::Integer)
    children = 0
    state.id += 1
    state.depth[v] = state.id
    state.low[v] = state.depth[v]

    for w in g.adj[v]
        if state.depth[w] == 0
            children += 1
            push!(state.stack, Edge(min(v, w), max(v, w)))
            bc_dfs!(g, state, v, w)
            state.low[v] = min(state.low[v], state.low[w])

            if (u == v && children > 1) || (u != v && state.low[w] >= state.depth[v])
                state.is_articulation[v] = true
                e = Edge(0, 0)  
                st = Vector{Edge}()
                while e != Edge(min(v, w),max(v, w))
                    e = pop!(state.stack)
                    push!(st, e)
                end
                push!(state.biconnected_comps, st)
            end

        elseif w != u && state.low[v] > state.depth[w]
            push!(state.stack, Edge(min(v, w), max(v, w)))
            state.low[v] = state.depth[w]
        end
    end
end

function do_bc_dfs(g::adjset_graph)
    state = Biconnections(g)
    for u in 1:g.n
        if state.depth[u] == 0
            bc_dfs!(g, state, u, u)
        end

        if !isempty(state.stack)
            push!(state.biconnected_comps, reverse(state.stack))
            empty!(state.stack)
        end
    end
    return state
end

function biconnected_components(g::adjset_graph)
    state = do_bc_dfs(g)
    return state.biconnected_comps
end

# Root a forest at the best possible roots, creating a parent array
# Root a forest at the best possible roots, creating a parent array
function root_forest(T::adjset_graph)
    vis_1 = falses(T.n)
    vis_2 = falses(T.n)
    vis_3 = falses(T.n)
    par = zeros(Int, T.n)
    dep = zeros(Int, T.n)
    v0 = 1
    while v0 <= T.n
        if par[v0] == 0 
            v = v0

            # BFS 1: random node (v) to furthest point (w)
            vis_1[v] = true
            S = [v]
            w = v
            while !isempty(S)
                w = S[1]
                deleteat!(S, 1)
                for nbr in T.adj[w]
                    if !vis_1[nbr]
                        vis_1[nbr] = true
                        push!(S, nbr)
                    end
                end
            end

            # BFS 2: previous furthest point (v <- w_old) to furthest point from it (w)
            v = w 
            S = [(v, 0)]
            vis_2[v] = true
            d = 0

            while !isempty(S)
                w, d = S[1]
                deleteat!(S,1)
                for nbr in T.adj[w]
                    if !vis_2[nbr]
                        vis_2[nbr] = true 
                        push!(S, (nbr, d+1))
                    end
                end
            end


            # DFS: go from v to w & find half-way mark - the root of the current tree
            S = [v]
            npops = div(d+(d%2),2)

            root = v
            hst = []
            while !isempty(S)
                wcur = pop!(S)
                push!(hst, wcur)
                vis_3[wcur] = true

                if wcur == w
                    root = pop!(hst)
                    for idx in 1:npops
                        root = pop!(hst)
                    end
                    break
                end
                for nbr in T.adj[wcur]
                    if !vis_3[nbr]
                        vis_3[nbr] = true 
                        push!(S, nbr)
                    end
                end
            end

            # Root the parent array at root with... yet another DFS!
            S = [root]
            par[root] = root # parent of root is itself by definition
            while !isempty(S)
                w = pop!(S)
                for nbr in T.adj[w]
                    if par[nbr] == 0
                        par[nbr] = w
                        dep[nbr] = dep[w] + 1
                        push!(S, nbr)
                    end
                end
            end
        end

        v0 += 1
    end
    return (par, dep)
end



# Get the block cut tree of an undirected graph
function block_cut_tree(g::adjset_graph)
    state = do_bc_dfs(g)
    a_pts = find(state.is_articulation)
    N0 = length(state.biconnected_comps)
    N1 = length(a_pts)
    N  = N0 + N1
    a_lkup = Dict{Int,Int}(a_pts[i] => N0+i for i in 1:N1)
    bctree = adjset_graph(N)
    v_lkup = zeros(Int,g.n)

    for cpt in 1:N0
        for e in state.biconnected_comps[cpt]
            if state.is_articulation[e.u]
                add_edge!(bctree, a_lkup[e.u], cpt)
                v_lkup[e.u] = a_lkup[e.u]
            else 
                v_lkup[e.u] = cpt 
            end
            if state.is_articulation[e.v]
                add_edge!(bctree, a_lkup[e.v], cpt)
                v_lkup[e.v] = a_lkup[e.v]
            else 
                v_lkup[e.v] = cpt 
            end
        end
    end

    return (v_lkup, bctree)
end

function scratch_bc()
    # sample code
    g = adjset_graph(9)
    add_edge!(g, 1,2)
    add_edge!(g, 1,3)
    add_edge!(g, 2,4)
    add_edge!(g, 3,4)
    add_edge!(g, 4,5)
    add_edge!(g, 4,6)
    add_edge!(g, 5,7)
    add_edge!(g, 6,7)
    add_edge!(g, 5,9)
    add_edge!(g, 7,8)
    add_edge!(g, 8,9)
    add_edge!(g, 7,10)
    add_edge!(g, 10,11)
    add_edge!(g, 10,12)

    biconnected_components(g)
end


#################################################################
#          Fast intersection of two sorted lists                #
#################################################################

function intersect_sorted(x::Vector{Int}, y::Vector{Int})
    if isempty(x) || isempty(y)
        return Vector{Int}
    end
    px = 1
    py = 1
    sol = Vector{Int}()
    while px <= length(x) && py <= length(y)
        while px <= length(x) && x[px] < y[py] 
            px += 1
        end
        if px > length(x)
            break
        end

        while py <= length(y) && y[py] < x[px]
            py += 1
        end
        if py > length(y)
            break
        end
        
        while px <= length(x) && py <= length(y) && x[px] == y[py]
            push!(sol, x[px])
            px += 1
            py += 1
        end
    end
    return sol
end



##################################################################
# TRIE
##################################################################
type MinTrie
    value::Int
    children::Dict{Char,MinTrie}
end

