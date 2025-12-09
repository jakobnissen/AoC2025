module Day9

using MemoryViews: ImmutableMemoryView
using BufferIO: line_views
using StringViews: StringView

import ..@nota, ..InputError, ..split_once, ..n_choose_two

function solve(mem::ImmutableMemoryView{UInt8})
    points = @nota InputError parse(mem)
    # Get all (area, point1, point2), sorted from largest to smallest area
    candidates = sorted_candidate_pairs(points)
    # This allows easy checking the line between first/last points, since now, all lines
    # are between adjecant points in the list `points`
    push!(points, first(points))
    p1 = first(first(candidates))
    for (area, point1, point2) in candidates
        # We determine if a rectangle is valid by checking if any of the lines
        # intersect with the rectangle.
        is_valid = true
        (rect_x_min, rect_x_max) = minmax(point1[1], point2[1])
        (rect_y_min, rect_y_max) = minmax(point1[2], point2[2])
        for (pointa, pointb) in zip(ImmutableMemoryView(points), ImmutableMemoryView(points)[2:end])
            if pointa[1] == pointb[1]
                # If line is vertical
                line_x = pointa[1]
                (line_y_min, line_y_max) = minmax(pointa[2], pointb[2])
                if line_x > rect_x_min && line_x < rect_x_max &&
                        line_y_max > rect_y_min && line_y_min < rect_y_max
                    is_valid = false
                    break
                end
            elseif pointa[2] == pointb[2]
                # Line is horizontal
                line_y = pointa[2]
                (line_x_min, line_x_max) = minmax(pointa[1], pointb[1])
                if line_y > rect_y_min && line_y < rect_y_max &&
                        line_x_max > rect_x_min && line_x_min < rect_x_max
                    is_valid = false
                    break
                end
            else
                # we checked line is either horizontal or vertical when parsing
                throw(AssertionError())
            end
        end
        is_valid && return (p1, area)
    end
    # Unreachable - we know at least one is valid.
    # This is true for any parseable input
    throw(AssertionError())
end

# Parse to a vector of (x_coordinate, y_coordinate), with a bunch of checks
function parse(mem::ImmutableMemoryView{UInt8})::Union{InputError, Vector{Tuple{Int32, Int32}}}
    result = Tuple{Int32, Int32}[]
    last = (Int32(0), Int32(0))
    for (line_number, line) in enumerate(line_views(mem))
        (as, bs) = @something(
            split_once(StringView(line), UInt8(',')),
            return InputError(line_number, "Line does not contain comma")
        )
        a = @something tryparse(Int32, as) return InputError(line_number, "Could not parse left as Int32")
        b = @something tryparse(Int32, bs) return InputError(line_number, "Could not parse right as Int32")
        push!(result, (a, b))
        if !(length(result) == 1 || last[1] == a || last[2] == b)
            return InputError(line_number, "Adjecant points not aligned")
        end
        last = (a, b)
    end
    length(result) > typemax(UInt16) && return InputError(nothing, "Too many points to handle")
    isempty(result) && return InputError(nothing, "No points")
    fst = @inbounds first(result)
    fst[1] == last[1] || fst[2] == last[2] || return InputError(length(result), "Adjecant points not aligned")
    return result
end

calc_area(x::NTuple{2, <:Tuple{Real, Real}}) = *(map(j -> abs(j) + 1, (x[1] .- x[2]))...)

# Compute all pairs of points, and sort them by their resulting area,
# so we can search from the largest area in part 2
function sorted_candidate_pairs(points::Vector{T}) where {T <: Tuple{Real, Real}}
    result = Vector{Tuple{Int, T, T}}(undef, n_choose_two(length(points) % UInt16) % Int)
    wi = 0
    for i in 1:(length(points) - 1), j in (i + 1):length(points)
        (p1, p2) = (points[i], points[j])
        result[(wi += 1)] = (calc_area((p1, p2)), p1, p2)
    end
    return sort!(result; by = first, rev = true)
end

end # module
