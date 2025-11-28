function split_once(s::StringView{<:MemoryView}, byte::UInt8)
    mem = codeunits(s)::MemoryView{UInt8}
    p = findfirst(==(byte), ImmutableMemoryView(mem))
    p === nothing && return nothing
    return @inbounds (StringView(mem[1:(p - 1)]), StringView(mem[(p + 1):end]))
end
