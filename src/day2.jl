module Day2

using StringViews: StringView
using MemoryViews: MemoryView, ImmutableMemoryView

import ..InputError, ..@nota, ..split_once

# For each number of digits, say 6, we compute all the ways the digits can be split:
# 2 x 3 digits, 3 x 2 digits and 6 x 1 digit.
# For each (say, 2 x 3 digits), we compute:
# * A modulo 10^3, to get the last 3 digits
# * 001001, a factor to multiply to the modulo'd value. If, after multiplying, we get
#   the same number as before modulo, then the number is periodical
# * A boolean which is true if the split is 2 x N, i.e. suitable for part 1.
const PRECOMPUTE = let
    result = Vector{Vector{Tuple{UInt, UInt, Bool}}}()
    for n_digits in 1:ndigits(typemax(UInt))
        v = eltype(result)()
        for chunk_size in div(n_digits, 2):-1:1
            n_chunks, remainder = divrem(n_digits, chunk_size)
            iszero(remainder) || continue
            is_half = (chunk_size * 2) == n_digits
            modulo = UInt(10)^(chunk_size)
            factor = UInt(1)
            for i in 1:(n_chunks - 1)
                factor = factor * modulo + UInt(1)
            end
            push!(v, (factor, modulo, is_half))
        end
        push!(result, v)
    end
    result
end

function solve(mem::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{String, String}}
    v = @nota InputError parse(mem)
    split_by_ndigits!(v)
    p1 = p2 = 0
    for range in v
        (_p1, _p2) = count_range(range)
        p1 += _p1
        p2 += _p2
    end
    return (string(p1), string(p2))
end

# We check each number individually. This way, we don't double count numbers such as
# 12121212, which is both 1212 1212 and 12 12 12 12. 
function count_range(range::UnitRange{UInt})::Tuple{Int, Int}
    # All numbers in the range must have same number of digits, we use
    # split_by_ndigits to achieve this.
    localv = PRECOMPUTE[ndigits(first(range))]
    p1 = p2 = 0
    for n in range
        for (factor, modulator, is_half) in localv
            modded = n % modulator
            if modded * factor == n
                p1 += n * is_half
                p2 += n
                break
            end
        end
    end
    return (p1, p2)
end

# To simplify the problem, if we have a range like 94-128, we split it into multiple ranges,
# where all number in each resulting range has the same number of digits. In this case,
# 94-99 and 100-128.
# Then, we can process each range more efficiently 
function split_by_ndigits!(v::Vector{UnitRange{T}}) where {T <: Unsigned}
    len = length(v)
    for i in len:-1:1
        rng = @inbounds v[i]
        (fst, lst) = (first(rng), last(rng))
        (ndfst, ndlst) = (ndigits(fst), ndigits(lst))
        ndfst == ndlst && continue
        v[i] = fst:(T(10)^ndfst - T(1))
        push!(v, (T(10)^(ndlst - 1)):lst)
        for j in (ndfst + 1):(ndlst - 1)
            push!(v, (T(10)^(j - 1)):(T(10)^j - 1))
        end
    end
    return v
end

function parse(mem::ImmutableMemoryView{UInt8})::Union{InputError, Vector{UnitRange{UInt}}}
    str = StringView(mem)
    result = UnitRange{UInt}[]
    for range_str in eachsplit(str, ',')
        (leftstr, rightstr) = @something split_once(range_str, UInt8('-')) return InputError(1)
        left = @something tryparse(UInt, leftstr) return InputError(1)
        right = @something tryparse(UInt, rightstr) return InputError(1)
        right < left && return InputError(1)
        push!(result, (left:right))
    end
    return result
end

end # module
