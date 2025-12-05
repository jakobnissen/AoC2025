module Day2

using StringViews: StringView
using MemoryViews: MemoryView, ImmutableMemoryView

import ..InputError, ..@nota, ..split_once

# For each possible number of digits in an UINt, say 6,
# we compute all the ways the digits can be split:
# 2 x 3 digits, 3 x 2 digits and 6 x 1 digit.
# For each (say, 2 x 3 digits), we compute:
# * A divisor, to extract to top 3 digits of the start of the range,
#   which represents the smallest possible periodical number in the range.
#   That is, if the range start is 312413, then the smallest number that could
#   possibly be in this range is the first 3 digits, repeated, i.e. 312312.
#   Similarly, we can get the largest possible periodical by doing the same operation
#   on the end of the range.
# * A factor 001001, used to build periodicals with the right number of digits.
#   by multiplying all integers start:stop with this factor, we get all periodicals with 2 chunks
#   of 3 repeated digits
const PRECOMPUTE = let
    result = Vector{Vector{Tuple{UInt, UInt}}}()
    for n_digits in 1:ndigits(typemax(UInt))
        v = eltype(result)()
        for chunk_size in div(n_digits, 2):-1:1
            n_chunks, remainder = divrem(n_digits, chunk_size)
            iszero(remainder) || continue
            modulo = UInt(10)^(chunk_size)
            factor = UInt(1)
            for _ in 1:(n_chunks - 1)
                factor = factor * modulo + UInt(1)
            end
            divisor = UInt(10)^(n_digits - chunk_size)
            push!(v, (divisor, factor))
        end
        push!(result, v)
    end
    result
end

function solve(mem::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{Any, Any}}
    v = @nota InputError parse(mem)
    split_by_ndigits!(v)
    result = (0, 0)
    periodicals = Set{UInt}()
    for range in v
        result = result .+ count_range!(periodicals, range)
    end
    return result
end

function count_range!(periodicals::Set{UInt}, range::UnitRange{UInt})::Tuple{Int, Int}
    # All numbers in the range must have same number of digits, we use
    # split_by_ndigits to achieve this.
    empty!(periodicals)
    localv = PRECOMPUTE[ndigits(first(range))]
    p1 = 0
    for (div_idx, (divisor, factor)) in enumerate(localv)
        for i in div(first(range), divisor):div(last(range), divisor)
            periodical = factor * i
            if periodical ∈ range
                push!(periodicals, periodical)
                p1 += periodical * isone(div_idx)
            end
            periodical > last(range) && break
        end
    end
    p2 = sum(periodicals)
    return (p1, p2)
end

# To simplify the problem, if we have a range like 94-128, we split it into multiple ranges,
# where all number in each resulting range has the same number of digits. In this case,
# 94-99 and 100-128.
# Then, we can process each range more efficiently
function split_by_ndigits!(v::Vector{UnitRange{T}}) where {T <: Unsigned}
    for i in eachindex(v)
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
