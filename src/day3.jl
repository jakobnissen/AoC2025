module Day3

using MemoryViews: ImmutableMemoryView
using BufferIO: line_views
import ..InputError

function solve(mem::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{Any, Any}}
    v = Vector{UInt8}(undef, 128)
    p1 = p2 = 0
    for (line_number, line) in enumerate(line_views(mem))
        length(line) < 12 && return InputError(line_number)
        length(line) > length(v) && resize!(v, length(line))
        bad_byte = false
        @inbounds for i in eachindex(line)
            byte = line[i] - 0x30
            v[i] = byte
            bad_byte |= byte > 0x09
        end
        bad_byte && return InputError(line_number)
        bank = @inbounds ImmutableMemoryView(v)[1:length(line)]
        p1 += joltage(bank, 2)
        p2 += joltage(bank, 12)
    end
    return (p1, p2)
end

function joltage(v::ImmutableMemoryView{T}, n::Int) where {T <: Unsigned}
    result = UInt(0)
    for digit in 1:n
        (mx, p) = findmax(v[1:(end - n + digit)])
        v = @inbounds v[(p + 1):end]
        result = 10 * result + mx
    end
    return result
end

end # module Day3
