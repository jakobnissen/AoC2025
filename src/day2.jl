module Day2

using StringViews: StringView
using MemoryViews: MemoryView, ImmutableMemoryView

import ..InputError, ..@nota, ..split_once

function solve(mem::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{String, String}}
    v = @nota InputError parse(mem)
    p1 = UInt(0)
    for (left, right) in v
        for i in left:right
            s = string(i)
            isodd(length(s)) && continue
            d = div(ncodeunits(s), 2)
            if view(s, 1:d) == view(s, d+1:ncodeunits(s))
                p1 += Base.parse(UInt, s)
            end
        end
    end
    p2 = UInt(0)
    for (left, right) in v
        for i in left:right
            s = string(i)
            ncu = ncodeunits(s)
            for divisor in 1:div(ncu, 2)
                d = div(ncu, divisor)
                d * divisor == ncu || continue
                v1 = Base.parse(UInt, view(s, 1:divisor))
                if all(divisor+1:divisor:ncu-divisor+1) do j
                    Base.parse(UInt, view(s, j:j+divisor-1)) == v1
                end
                    p2 += i
                    break
                end
            end
        end
    end
    return (string(p1), string(p2))
end

# function solve_range(u::UnitRange{<:Integer})
#     isempty(u) && return (0, 0)

# end

function parse(mem::ImmutableMemoryView{UInt8})::Union{InputError, Vector{Tuple{UInt, UInt}}}
    str = StringView(mem)
    result = Tuple{UInt, UInt}[]
    for range_str in eachsplit(str, ',')
        (leftstr, rightstr) = @something split_once(range_str, UInt8('-')) return InputError(1)
        left = @something tryparse(UInt, leftstr) return InputError(1)
        right = @something tryparse(UInt, rightstr) return InputError(1)
        right < left && return InputError(1)
        push!(result, (left, right))
    end
    return result
end

end # module