module Day4

using MemoryViews: ImmutableMemoryView
using BufferIO; line_views

import ..InputError, ..@nota

# The eight directions of a cell
const DELTAS = CartesianIndex.(
    [
        (-1, -1),
        (-1, 0),
        (-1, 1),
        (0, -1),
        (0, 1),
        (1, -1),
        (1, 0),
        (1, 1),
    ]
)

# Overall approach is to keep a list of indices which contain a roll that we need to
# check if it can be removed.
# For each roll we remove, we keep add its index to a set, and for each round of removal,
# we report on the length of this set.

# Then, for next round, we check all neighbors of the ones we removed.
function solve(mem::ImmutableMemoryView{UInt8})
    M = @nota InputError parse(mem)
    indices_to_check = collect(Iterators.filter(i -> M[i], CartesianIndices(M)))
    indices_to_remove = Set{eltype(indices_to_check)}()
    # Part 1 is only the first round
    p1 = p2 = n_removed = remove_rolls!(M, indices_to_check, indices_to_remove)
    while !iszero(n_removed)
        # For part 2, keep removing rolls until we are done.
        n_removed = remove_rolls!(M, indices_to_check, indices_to_remove)
        p2 += n_removed
    end
    return (string(p1), string(p2))
end

function remove_rolls!(
        M::BitMatrix,
        indices_to_check::Vector{CartesianIndex{2}},
        indices_to_remove::Set{CartesianIndex{2}},
    )
    for i in indices_to_check
        neighbors = count(d -> get(M, i + d, false), DELTAS)
        neighbors < 4 && push!(indices_to_remove, i)
    end
    # Add the neighbors of those we just removed to `indices_to_check`,
    # since these may be eligible for removal in the next round.
    empty!(indices_to_check)
    n_removed = length(indices_to_remove)
    for i in indices_to_remove
        M[i] = false
        for d in DELTAS
            # In next round, only check those that have a roll, and which we
            # are not removing in this round.
            get(M, d + i, false) &&
                !in(d + i, indices_to_remove) &&
                push!(indices_to_check, d + i)
        end
    end
    empty!(indices_to_remove)
    return n_removed
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
