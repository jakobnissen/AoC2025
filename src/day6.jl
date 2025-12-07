module Day6

using MemoryViews: MemoryView, ImmutableMemoryView
using BufferIO: line_views
using StringViews: StringView

import ..InputError, ..@nota

@enum Operation::UInt8 mul add

struct Block
    horizontal::ImmutableMemoryView{Int}
    vertical::ImmutableMemoryView{Int}
    op::Operation
end

reduce(op::Operation, it::AbstractVector{Int}) = op == mul ? prod(it; init = 1) : sum(it; init = 0)
reduce(b::Block) = (reduce(b.op, b.horizontal), reduce(b.op, b.vertical))

function solve(mem::ImmutableMemoryView{UInt8})
    result = (0, 0)
    for block in (@nota InputError parse(mem))
        result = result .+ reduce(block)
    end
    return result
end

function parse(mem::ImmutableMemoryView{UInt8})::Union{Vector{Block}, InputError}
    lines = ImmutableMemoryView(collect(line_views(mem)))
    length(lines) < 2 && return InputError(nothing, "Must have at least two lines")
    allequal(length, lines) || return InputError(nothing, "Line lengths must be the same")

    # Get a all lines but the last as matrix of bytes
    M = stack(lines[1:(end - 1)], dims = 1)

    # Get UnitRanges of the column indices that are not all spaces.
    spaces = findall(map(i -> all(==(UInt8(' ')), i), eachcol(M)))
    spans = [1:(first(spaces) - 1)]
    append!(spans, (i + 1):(j - 1) for (i, j) in zip(spaces, spaces[2:end]))
    push!(spans, (last(spaces) + 1):size(M, 2))
    filter!(!isempty, spans)
    # For each horizontal span, we get the corresponding view of the matrix,
    # then get the single op corresponding to that view, and parse the integers
    # horizontally and vertically
    opline = last(lines)
    h_nums = Int[]
    v_nums = Int[]
    result = Block[]
    for span in spans
        # Parse operation - exactly one * or + in the final row
        op = let
            s = strip(StringView(opline[span]))
            ncodeunits(s) == 1 || return InputError(length(lines), "No * or + aligned with number block")
            cu = codeunit(s, 1)
            cu == UInt8('*') ? mul : (cu == UInt8('+') ? add : return InputError(length(lines)))
        end

        # Parse horizontally
        S = view(M, :, span)
        for (rownum, row) in enumerate(eachrow(S))
            num = tryparse(Int, StringView(row))
            num === nothing && return InputError(rownum, "Could not parse row as integer")
            push!(h_nums, num)
        end
        horizontal = ImmutableMemoryView(h_nums)[(end - size(S, 1) + 1):end]

        # Parse vertically
        for col in eachcol(S)
            num = tryparse(Int, StringView(col))
            num === nothing && return InputError(nothing, "Could not parse column as integer")
            push!(v_nums, num)
        end
        vertical = ImmutableMemoryView(v_nums)[(end - size(S, 2) + 1):end]

        push!(result, Block(horizontal, vertical, op))
    end
    return result
end

end # module Day6
