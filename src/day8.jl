module Day8

using MemoryViews: ImmutableMemoryView, split_each
using BufferIO: line_views
using StringViews: StringView

import ..@nota, ..InputError, ..n_choose_two

struct Point
    coords::NTuple{3, Int32}
end

distance(a::Point, b::Point) = Float32(sum(Int.((a.coords .- b.coords)) .^ 2; init = 0))

function Base.tryparse(::Type{Point}, line::AbstractString)
    it = eachsplit(line, ',')
    (s, st) = something(iterate(it))
    a = @something tryparse(Int32, s) return nothing
    (s, st) = @something iterate(it, st) return nothing
    b = @something tryparse(Int32, s) return nothing
    (s, st) = @something iterate(it, st) return nothing
    c = @something tryparse(Int32, s) return nothing
    isnothing(iterate(it, st)) || return nothing
    return Point((a, b, c))
end

# We use the function barrier trick to avoid weird type inference when looping over a union-typed value.
# In the absence of a function barrier, both the iterable and the state to be union-typed,
# and the compiler cannot infer that one type of the iterable goes with one type of the state.
function assign(circuits, small, big)
    for i in small
        circuits[i] = big
    end
    return
end

function solve(mem::ImmutableMemoryView{UInt8})
    points = ImmutableMemoryView(@nota(InputError, parse(mem)))

    # In the beginning, each junction box is its own circuit (a number).
    # When they are joined together, we store all members of their circuit in this list
    circuits = Union{Int, Vector{UInt16}}[i for i in eachindex(points)]

    # When two junction boxes link together, they both store a reference to the same
    # circuit. Hence, `circuits` contain duplicates and so the number of circuits
    # is NOT the same as its length.
    n_circuits = length(points)
    p1 = p2 = 0
    for (connection_number, (_, i, j)) in enumerate(get_sorted_neighbors(points))
        big_circuit = circuits[i]
        small_circuit = circuits[j]

        # No need to do anything when linking junction boxes of same circuit
        big_circuit === small_circuit && continue

        # For efficiency, we copy the smaller circuit into the longer.
        if length(small_circuit) > length(big_circuit)
            (small_circuit, big_circuit) = (big_circuit, small_circuit)
        end

        if big_circuit isa Int
            big_circuit = [i, j]
            circuits[i] = big_circuit
            circuits[j] = big_circuit
        else
            # Every element in the small circuit is now in the big circuit
            append!(big_circuit, small_circuit)
            assign(circuits, small_circuit, big_circuit)
        end

        # Solve part 1 when 1,000 connections has been made
        if connection_number == 1000
            unique_circuits = partialsort!(unique_by_identity(circuits), 1:3; by = length, rev = true)
            p1 = prod(length, unique_circuits; init = 1)
        end

        # Solve part 2 when all circuits have been connected
        n_circuits -= 1
        if n_circuits == 1
            p2 = Int(points[i].coords[1]) * Int(points[j].coords[1])
            return (p1, p2)
        end
    end
    throw(AssertionError())
end

unique_by_identity(it) = collect(IdSet{eltype(it)}(it))

function get_sorted_neighbors(v::ImmutableMemoryView{Point})
    length(v) > typemax(UInt16) && error("Can only handle 2^16-1 points in day 8")
    len = length(v) % UInt16
    d = Vector{Tuple{Float32, UInt16, UInt16}}(undef, n_choose_two(len) % Int)
    wi = 0
    @inbounds for i in 1:(len - 1)
        a = v[i]
        for j in (i + 1):len
            d[(wi += 1)] = (distance(a, v[j]), i % UInt16, j % UInt16)
        end
    end
    sort!(d; by = first)
    return d
end

function parse(mem::ImmutableMemoryView{UInt8})
    points = Point[]
    for (line_number, line) in enumerate(line_views(mem))
        point = @something tryparse(Point, StringView(line)) return InputError(line_number)
        push!(points, point)
    end
    return points
end

end # module Day8
