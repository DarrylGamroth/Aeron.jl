@inline function rstrip_nul(a::AbstractVector{UInt8})
    pos = findfirst(iszero, a)
    len = pos !== nothing ? pos - 1 : Base.length(a)
    return view(a, 1:len)
end