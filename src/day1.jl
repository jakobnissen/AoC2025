module Day1

using BufferIO: line_views
using StringViews: StringView
using MemoryViews: MemoryView, ImmutableMemoryView

import ..InputError, ..@nota

function solve(data::ImmutableMemoryView{UInt8})::Union{InputError, Tuple{Any, Any}}
    v = @nota InputError parse(data)
    p1 = p2 = 0
    dial = 50
    for i in v
        new_dial = dial + i
        p2 += div(abs(new_dial) % UInt, UInt(100)) % Int + ((new_dial < 1) & (dial > 0))
        dial = mod(new_dial, 100)
        p1 += iszero(dial)
    end
    return (p1, p2)
end

function parse(data::ImmutableMemoryView{UInt8})::Union{InputError, Vector{Int32}}
    result = Int32[]
    for (line_number, line) in enumerate(Iterators.map(StringView, line_views(data)))
        n = @something tryparse_rotation(line) return InputError(line_number)
        push!(result, n)
    end
    return result
end

function tryparse_rotation(s::StringView{<:MemoryView})::Union{Int32, Nothing}
    cu = codeunits(s)
    length(cu) < 2 && return nothing
    s = @inbounds cu[1]
    neg = if s == UInt8('R')
        false
    elseif s == UInt8('L')
        true
    else
        return nothing
    end
    n = @something tryparse(Int32, StringView(@inbounds(cu[2:end]))) return nothing
    n < 0 && return nothing
    return neg ? -n : n
end

end # module
