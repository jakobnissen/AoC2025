module Day5

using MemoryViews: ImmutableMemoryView
using StringViews: StringView
using BufferIO: line_views

import ..InputError, ..@nota

function solve(mem::ImmutableMemoryView{UInt8})
    (ranges, ids) = @nota InputError parse(mem)
    ranges = ImmutableMemoryView(collapse_ranges!(ranges))

    p1 = count(i -> in_sorted_ranges(i, ranges), ids)
    p2 = sum(length, ranges; init = 0)

    return string(p1), string(p2)
end

function collapse_ranges!(v::Vector{<:UnitRange})
    sort!(v; by = first, alg = QuickSort)
    length(v) < 2 && return v
    wi = 1
    rng = first(v)
    (start, stop) = (first(rng), last(rng))
    @inbounds for ri in 2:length(v)
        rng = v[ri]
        if first(rng) > stop + 1
            v[wi] = start:stop
            (start, stop) = (first(rng), last(rng))
            wi += 1
        else
            stop = max(stop, last(rng))
        end
    end
    @inbounds v[wi] = start:stop
    resize!(v, wi)
    return v
end

function in_sorted_ranges(i::Integer, v::ImmutableMemoryView{<:UnitRange})
    isempty(v) && return false
    lo = 1
    hi = length(v)
    i < first(@inbounds(v[lo])) && return false
    i > last(@inbounds(v[hi])) && return false
    return @inbounds while true
        lo < hi && return false
        mid = (lo + hi) >> 1
        rng = v[mid]
        if i < first(rng)
            hi = mid - 1
        elseif i > last(rng)
            lo = mid + 1
        else
            return true
        end
    end
end

function parse(mem::ImmutableMemoryView)
    lines = ImmutableMemoryView(collect(line_views(mem)))
    empty_index = @something findfirst(isempty, lines) return InputError(nothing)

    # Parse ID ranges
    ranges = Vector{UnitRange{Int}}(undef, empty_index - 1)
    for (line_number, line) in enumerate(lines[1:(empty_index - 1)])
        p = @something findfirst(==(UInt8('-')), line) return InputError(line_number)
        a = @something tryparse(Int, StringView(line[1:(p - 1)])) return InputError(line_number)
        b = @something tryparse(Int, StringView(line[(p + 1):end])) return InputError(line_number)
        a > b && return InputError(line_number)
        ranges[line_number] = a:b
    end

    # Parse Ingredient IDs
    ids = Vector{Int}(undef, length(lines) - empty_index)
    for (line_number_2, line) in enumerate(lines[(empty_index + 1):end])
        id = @something(
            tryparse(Int, StringView(line)),
            return InputError(line_number_2 + empty_index)
        )
        ids[line_number_2] = id
    end

    return (ranges, ids)
end

end # module Day5
