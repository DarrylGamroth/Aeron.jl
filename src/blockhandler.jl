abstract type AbstractBlockHandler end

mutable struct BlockHandler{T<:Function, C} <: AbstractBlockHandler
    on_block_handler::T
    clientd::C
    function BlockHandler(on_block_handler::T, clientd::C=nothing) where {T<:Function, C}
        new{T, C}(on_block_handler, clientd)
    end
end

function on_block_wrapper(b::AbstractBlockHandler, buffer, length, session_id, term_id)
    b.on_block_handler(b.clientd, UnsafeArray(buffer, (Int64(length),)), session_id, term_id)
    nothing
end

on_block_clientd(f::BlockHandler) = Ref(f)

function on_block_cfunction(::T) where {T<:AbstractBlockHandler}
    @cfunction(on_block_wrapper, Cvoid, (Ref{T}, Ptr{UInt8}, Csize_t, Int32, Int32))
end
