"""
    abstract type AbstractControlledFragmentHandler

An abstract type for controlled fragment handlers in Aeron.

This serves as a base type for different implementations of controlled fragment handlers.
"""
abstract type AbstractControlledFragmentHandler end

"""
    struct ControlledFragmentHandler{T, C} <: AbstractControlledFragmentHandler

Represents a controlled fragment handler with a callback function and client data.

# Fields

- `on_fragment::T`: The function called when a fragment is received.
- `clientd::C`: Client data passed to the handler function.

# Constructor

- `ControlledFragmentHandler(on_fragment::T, clientd::C=nothing)`: Creates a new `ControlledFragmentHandler` with the given handler function and client data.

# Arguments

- `on_fragment::T`: The function called when a fragment is received. The signature of the function is `function(clientd::Any, buffer::AbstractVector{UInt8}, header::Header) -> ControlledAction`.
- `clientd::Any=nothing`: Client data passed to the handler function.
"""
mutable struct ControlledFragmentHandler{T,C} <: AbstractControlledFragmentHandler
    on_fragment::T
    clientd::C
    function ControlledFragmentHandler(on_fragment::T, clientd::C=nothing) where {T,C}
        new{T,C}(on_fragment, clientd)
    end
end

on_fragment(f::ControlledFragmentHandler) = f.on_fragment
clientd(f::ControlledFragmentHandler) = f.clientd

function on_fragment_wrapper(f::AbstractControlledFragmentHandler, buffer, length, header)
    action = on_fragment(f)(clientd(f), UnsafeArray(buffer, (Int64(length),)), Header(header))
    return aeron_controlled_fragment_handler_action_t(Integer(action))
end

function on_fragment_cfunction(::T) where {T<:AbstractControlledFragmentHandler}
    @cfunction(on_fragment_wrapper,
        aeron_controlled_fragment_handler_action_t,
        (Ref{T}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end
