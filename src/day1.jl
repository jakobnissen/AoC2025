module Day1

function solve(s::String)
    (left, right) = (Int[], Int[])
    for line in eachline(IOBuffer(s))
        (a, b) = map(i -> parse(Int, i), eachsplit(line))
        push!(left, a)
        push!(right, b)
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