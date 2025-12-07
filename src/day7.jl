module Day7

using MemoryViews: ImmutableMemoryView
using BufferIO: line_views

import ..InputError, ..@nota

function solve(mem::ImmutableMemoryView{UInt8})
    # We iterate over rows from top down, and for each col in the current row
    # we count the number of paths leading to that col.
    (M, start) = @nota InputError parse(mem)
    paths = zeros(Int, size(M, 2))
    next = copy(paths) # paths in next round
    paths[start] = 1
    p1 = 0
    for row in collect(eachrow(M))
        fill!(next, 0)
        for i in eachindex(paths, next, row)
            # Beam split: Split to left and right paths in next round
            if row[i]
                iszero(paths[i]) && continue
                p1 += 1
                i > 1 && (next[i - 1] += paths[i])
                i < length(paths) && (next[i + 1] += paths[i])
            else
                # No beam split: Carry forward previous paths
                next[i] += paths[i]
            end
        end
        (next, paths) = (paths, next)
    end
    p2 = sum(paths; init = 0)
    return (p1, p2)
end

function parse(mem::ImmutableMemoryView)::Union{InputError, Tuple{BitMatrix, Int}}
    lines = ImmutableMemoryView(collect(line_views(mem)))
    isempty(lines) && return InputError(nothing, "Input is empty")
    first_line = lines[1]
    # Find starting index in first line
    start = @something findfirst(==(UInt8('S')), first_line) return InputError(1)
    # Ensure first line has nothing other than 1 S and rest is dots
    for i in eachindex(first_line)
        i == start && continue
        first_line[i] == UInt8('.') || return InputError(
            1, "First line must contain only 'S' or '.'"
        )
    end
    # All lines must have same length
    allequal(length, lines) || return InputError(nothing, "Line lengths are not equal")
    M = falses(length(lines) - 1, length(first(lines)))
    # Parse all other lines than first line as ^ being true, '.' being false
    for (line_number_m1, line) in enumerate(lines[2:end])
        for (i, byte) in enumerate(line)
            M[line_number_m1, i] = if byte == UInt8('.')
                false
            elseif byte == UInt8('^')
                true
            else
                return InputError(line_number_m1 + 1, "Invalid byte: Must be '.' or '^'")
            end
        end
    end
    return (M, start)
end

end # module Day 7
