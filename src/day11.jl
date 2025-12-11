module Day11

using MemoryViews: ImmutableMemoryView, split_each
using BufferIO: line_views
using StringViews: StringView

import ..InputError, ..@nota

function solve(mem::ImmutableMemoryView{UInt8})
    (; children, parents, you, svr, dac, fft, out) = @nota InputError parse(mem)
    all_nodes = Set(1:length(children))
    paths = zeros(Int, length(children))
    (F, L) = fft ∈ reachable_from(dac, children, all_nodes) ? (dac, fft) : (fft, dac)
    p1 = @nota InputError count_paths(you, out, children, parents, all_nodes, paths)
    p2 = *(
        @nota(InputError, count_paths(svr, F, children, parents, all_nodes, paths)),
        @nota(InputError, count_paths(F, L, children, parents, all_nodes, paths)),
        @nota(InputError, count_paths(L, out, children, parents, all_nodes, paths))
    )
    return (p1, p2)
end

function count_paths(
        from::Int,
        to::Int,
        children::Vector{Vector{Int}},
        parents::Vector{Vector{Int}},
        all_nodes::Set{Int},
        paths::Vector{Int},
    )
    # Only nodes reachable from `from`, and which can reach `to`, both indluded
    subgraph = reachable_from(to, parents, reachable_from(from, children, all_nodes))
    isempty(subgraph) && return InputError(nothing, "No paths between named nodes")
    topology = topological_order(subgraph, children, parents)
    isnothing(topology) && return InputError(nothing, "Cycle detected between named nodes")
    for i in topology
        paths[i] = 0
    end
    for i in topology
        paths[i] = i == from ? 1 : sum(paths[p] for p in parents[i]; init = 0)
    end
    return paths[to]
end

function topological_order(
        nodes::Set{Int},
        children::Vector{Vector{Int}},
        parents::Vector{Vector{Int}},
    )
    # Kahn's algorithm
    # Only consider the relevant subgraph, since we want this to succeed, even there are
    # cycles in irrelevant parts of the graph
    included_parents = Union{Nothing, Set{Int}}[nothing for _ in eachindex(parents)]
    for i in nodes
        included_parents[i] = intersect!(Set(parents[i]), nodes)
    end
    tops = [i for i in nodes if isempty(something(included_parents[i]))]
    result = Int[]
    while !isempty(tops)
        node = pop!(tops)
        push!(result, node)
        for child in children[node]
            child ∈ nodes || continue
            par = something(included_parents[child])
            delete!(par, node)
            if isempty(par)
                push!(tops, child)
            end
        end
    end
    # This is true iff there is a cycle in our graph
    if any(i -> !isempty(something(included_parents[i])), nodes)
        return nothing
    else
        return result
    end
end

function reachable_from(node::Int, children::Vector{Vector{Int}}, consider::Set{Int})
    node ∈ consider || return Set{Int}()
    visited = Set([node])
    next = copy(visited)
    while !isempty(next)
        node = pop!(next)
        push!(visited, node)
        for child in children[node]
            child ∉ visited && child ∈ consider && push!(next, child)
        end
    end
    return visited
end

function parse(mem::ImmutableMemoryView{UInt8})
    index_by_name = Dict{ImmutableMemoryView{UInt8}, Int}()
    children = Vector{Int}[]
    seen_parents = BitSet()
    children_on_line = Set{Int}()

    function make_or_get_node(name)
        return get!(index_by_name, name) do
            idx = length(index_by_name) + 1
            push!(children, eltype(children)())
            idx
        end
    end

    for (line_number, line) in enumerate(line_views(mem))
        fields = Iterators.peel(split_each(line, UInt8(' ')))
        fields === nothing && return InputError(line_number, "Line is empty")
        (parent_name, rest) = fields
        if length(parent_name) < 2 || @inbounds(parent_name[end]) != UInt8(':')
            return InputError(line_number, "Parent not formatted as '<id>:'")
        end
        parent = make_or_get_node(@inbounds(parent_name[1:(end - 1)]))
        in!(parent, seen_parents) && return InputError(line_number, "Parent seen more than once")
        empty!(children_on_line)
        for child_name in rest
            make_or_get_node(child_name)
            child = get!(() -> length(index_by_name) + 1, index_by_name, child_name)
            in!(child, children_on_line) && return InputError(line_number, "Duplicate child on line")
        end
        append!(children[parent], children_on_line)
    end

    special_names = ["you", "svr", "dac", "fft", "out"]
    special_nodes = Int[]
    for name in special_names
        idx = get(index_by_name, ImmutableMemoryView(name), nothing)
        if isnothing(idx)
            s = "Missing key: " * name
            return InputError(nothing, s)
        end
        push!(special_nodes, idx)
    end

    parents = [Int[] for _ in eachindex(children)]
    for (i, chd) in enumerate(children), child in chd
        push!(parents[child], i)
    end

    return (;
        children,
        parents,
        you = special_nodes[1],
        svr = special_nodes[2],
        dac = special_nodes[3],
        fft = special_nodes[4],
        out = special_nodes[5],
    )
end

end # module Day11
