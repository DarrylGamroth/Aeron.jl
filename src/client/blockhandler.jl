"""
    abstract type AbstractBlockHandler

An abstract type for block handlers in Aeron.

This serves as a base type for different implementations of block handlers.
"""
abstract type AbstractBlockHandler end

"""
    struct BlockHandler{T<:Function, C} <: AbstractBlockHandler

Represents a block handler with a callback function and client data.

# Fields

- `on_block_handler::T`: The function called when a block of messages is received.
- `clientd::C`: Client data passed to the handler function.

# Constructor

- `BlockHandler(on_block_handler::T, clientd::C=nothing)`: Creates a new `BlockHandler` with the given handler function and client data.

# Arguments

- `on_block_handler::T`: The function called when a block is received. The signature of the function is `function(clientd::Any, buffer::AbstractVector{UInt8}, session_id::Int32, term_id::Int32) -> Nothing`.
- `clientd::Any=nothing`: Client data passed to the handler function.
"""
mutable struct BlockHandler{T<:Function,C} <: AbstractBlockHandler
    on_block_handler::T
    clientd::C
    function BlockHandler(on_block_handler::T, clientd::C=nothing) where {T<:Function,C}
        new{T,C}(on_block_handler, clientd)
    end
end

handler(b::BlockHandler) = b.on_block_handler
clientd(b::BlockHandler) = b.clientd

function on_block_wrapper(b::AbstractBlockHandler, buffer, length, session_id, term_id)
    handler(b)(clientd(b), UnsafeArray(buffer, (Int64(length),)), session_id, term_id)
    nothing
end

function on_block_cfunction(::T) where {T<:AbstractBlockHandler}
    @cfunction(on_block_wrapper, Cvoid, (Ref{T}, Ptr{UInt8}, Csize_t, Int32, Int32))
end
