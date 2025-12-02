const MemStrView = Union{
    StringView{<:MemoryView{UInt8}},
    SubString{<:StringView{<:MemoryView{UInt8}}}
}

function split_once(mem::MemoryView{UInt8}, byte::UInt8)
    pos = @something findfirst(==(byte), mem) return nothing
    left = @inbounds mem[1:pos-1]
    right = @inbounds mem[pos+1:end]
    return (left, right)
end

function split_once(mem::MemStrView, byte::UInt8)
    (left, right) = @something split_once(codeunits(mem), byte) return nothing
    return (StringView(left), StringView(right))
end