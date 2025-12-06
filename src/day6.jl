module Day6

using MemoryViews: MemoryView, ImmutableMemoryView
using BufferIO: line_views
using StringViews: StringView

f(mul, it) = mul ? prod(it) : sum(it)

function solve(mem::ImmutableMemoryView{UInt8})
    lines = ImmutableMemoryView(collect(line_views(mem)))
    ops = map(==("*"), eachsplit(StringView(last(lines))))
    M = stack(lines[1:end-1], dims=1)
    spaces = findall(map(i -> all(==(UInt8(' ')), i), eachcol(M)))
    spans = [1:first(spaces)-1]
    append!(spans, i+1:j-1 for (i,j) in zip(spaces, spaces[2:end]))
    push!(spans, last(spaces)+1:size(M, 2))
    p1 = p2 = 0
    for (op, span) in zip(ops, spans)
        S = M[:, span]
        p1 += f(op, (Base.parse(Int, StringView(i)) for i in eachrow(S)))
        p2 += f(op, (Base.parse(Int, StringView(i)) for i in eachcol(S)))
    end
    return (p1, p2)
end

end # module Day6