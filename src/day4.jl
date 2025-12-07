module Day4

using MemoryViews: ImmutableMemoryView
using BufferIO; line_views

import ..InputError, ..@nota

# The eight directions of a cell
const DELTAS = setdiff(CartesianIndices((-1:1, -1:1)), Ref(CartesianIndex(0, 0)))

function solve(mem::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{Any, Any}}
    M = @nota InputError parse(mem)
    neighbour_count = Matrix{UInt8}(undef, size(M))
    @inbounds for i in CartesianIndices(M)
        M[i] || continue
        neighbour_count[i] = count(d -> get(M, i + d, false), DELTAS) % UInt8
    end
    indices_to_remove = collect(Iterators.filter(i -> M[i] && neighbour_count[i] < 0x04, CartesianIndices(M)))
    p1 = length(indices_to_remove)
    p2 = 0
    while !isempty(indices_to_remove)
        i = pop!(indices_to_remove)
        p2 += 1
        M[i] = false
        for d in DELTAS
            get(M, i + d, false) || continue
            old = neighbour_count[i + d]
            neighbour_count[i + d] = old - 0x01
            old == 0x04 && push!(indices_to_remove, i + d)
        end
    end
    return (p1, p2)
end

# We parse it as a BitMatrix with @ being true.
# This function does the obvious thing - it's long because of error handling.
function parse(mem::ImmutableMemoryView{UInt8})::Union{BitMatrix, InputError}
    lines = line_views(mem)
    isempty(lines) && return InputError(nothing)
    first_line_len = length(first(lines))
    v = sizehint!(BitVector(), length(mem))
    n_lines = 0
    for (line_number, line) in enumerate(lines)
        n_lines += 1
        length(line) == first_line_len || return InputError(line_number)
        for i in line
            bool = if i == UInt8('@')
                true
            elseif i == UInt8('.')
                false
            else
                return InputError(line_number)
            end
            push!(v, bool)
        end
    end
    return BitMatrix(reshape(v, (n_lines, first_line_len))')
end

end # module Day4
