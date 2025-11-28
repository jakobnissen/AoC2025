module Day1

using BufferIO; line_views, CursorReader
using StringViews: StringView
using MemoryViews: ImmutableMemoryView

import ..split_once

function solve(data::ImmutableMemoryView{UInt8})::Tuple{String, String}
    (left, right) = (Int[], Int[])
    for (line_no, line) in enumerate(line_views(CursorReader(data)))
        (a, b) = something(split_once(StringView(line), UInt8(' ')))
        push!(left, parse(Int, a))
        push!(right, parse(Int, b))
    end
    sort!(left)
    sort!(right)
    right_counter = Dict{Int, Int}()
    for i in right
        right_counter[i] = get(right_counter, i, 0) + 1
    end
    p1 = string(sum(abs(i-j) for (i,j) in zip(left, right); init=0))
    p2 = string(sum(i * get(right_counter, i, 0) for i in left; init=0))
    return (p1, p2)
end

end # module