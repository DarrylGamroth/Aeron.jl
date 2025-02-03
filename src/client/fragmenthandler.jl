"""
    abstract type AbstractFragmentHandler

An abstract type for fragment handlers in Aeron.

This serves as a base type for different implementations of fragment handlers.
"""
abstract type AbstractFragmentHandler end

"""
    function on_fragment(f::AbstractFragmentHandler) -> Function

Returns the function called when a fragment is received.
"""
function on_fragment end

"""
    function clientd(f::AbstractFragmentHandler) -> Any

Returns the client data passed to the handler function.
"""
function clientd end

"""
    struct FragmentHandler{T, C} <: AbstractFragmentHandler

Represents a fragment handler with a callback function and client data.

# Fields

- `on_fragment::T`: The function called when a fragment is received.
- `clientd::C`: Client data passed to the handler function.

# Constructor

- `FragmentHandler(on_fragment::T, clientd::C=nothing)`: Creates a new `FragmentHandler` with the given handler function and client data.

# Arguments

- `on_fragment::T`: The function called when a fragment is received. The signature of the function is `function(clientd::Any, buffer::AbstractVector{UInt8}, header::Header) -> Nothing`.
- `clientd::Any=nothing`: Client data passed to the handler function.
"""
struct FragmentHandler{T,C} <: AbstractFragmentHandler
    on_fragment::T
    clientd::C
    function FragmentHandler(on_fragment::T, clientd::C=nothing) where {T,C}
        new{T,C}(on_fragment, clientd)
    end
end

on_fragment(f::FragmentHandler) = f.on_fragment
clientd(f::FragmentHandler) = f.clientd

function on_fragment_wrapper(f::AbstractFragmentHandler, buffer, length, header)
    on_fragment(f)(clientd(f), UnsafeArray(buffer, (Int64(length),)), Header(header))
    nothing
end

function on_fragment_cfunction(::T) where {T<:AbstractFragmentHandler}
    @cfunction(on_fragment_wrapper, Cvoid, (Ref{T}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end
