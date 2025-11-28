module Day1

using BufferIO; line_views, CursorReader
using StringViews: StringView
using MemoryViews: ImmutableMemoryView

import ..split_once, ..InputError

function solve(data::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{String, String}}
    (left, right) = (Int[], Int[])
    for (line_number, line) in enumerate(Iterators.map(StringView, line_views(CursorReader(data))))
        (a, b) = @something split_once(line, UInt8(' ')) return InputError(line_number)
        push!(left, @something(tryparse(Int, a), return InputError(line_number)))
        push!(right, @something(tryparse(Int, b), return InputError(line_number)))
    end
    sort!(left; alg=QuickSort)
    sort!(right; alg=QuickSort)
    right_counter = Dict{Int, Int}()
    for i in right
        right_counter[i] = get(right_counter, i, 0) + 1
    end
    p1 = string(sum(abs(i-j) for (i,j) in zip(left, right); init=0))
    p2 = string(sum(i * get(right_counter, i, 0) for i in left; init=0))
    return (p1, p2)
end

end # module