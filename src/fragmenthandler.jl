abstract type AbstractFragmentHandler end

mutable struct FragmentHandler{T<:Function, C} <: AbstractFragmentHandler
    on_fragment_handler::T
    clientd::C
end

FragmentHandler(on_fragment_handler) = FragmentHandler(on_fragment_handler, nothing)

function on_fragment_wrapper(f, buffer, length, header)
    f.on_fragment_handler(f.clientd, UnsafeArray(buffer, (Int64(length),)), Header(header))
    nothing
end

on_fragment_clientd(f::FragmentHandler) = Ref(f)

function on_fragment_cfunction(::T) where {T<:AbstractFragmentHandler}
    @cfunction(on_fragment_wrapper, Cvoid, (Ref{T}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end
