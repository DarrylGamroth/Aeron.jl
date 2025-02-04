abstract type AbstractReservedValueSupplier end

"""
    struct ReservedValueSupplier{T<:Function, C} <: AbstractReservedValueSupplier

Represents a reserved value supplier with a handler function and client data.

# Fields

- `handler::T`: The function called when filling in the reserved value field of a message.
- `clientd::C`: Client data passed to the handler function.

# Constructor

- `ReservedValueSupplier(handler::T, clientd::C=nothing)`: Creates a new `ReservedValueSupplier`
   with the given handler function and client data.
"""
mutable struct ReservedValueSupplier{T<:Function,C} <: AbstractReservedValueSupplier
    handler::T
    clientd::C
    function ReservedValueSupplier(handler::T, clientd::C=nothing) where {T<:Function,C}
        new{T,C}(handler, clientd)
    end
end

handler(r::ReservedValueSupplier) = r.handler
clientd(r::ReservedValueSupplier) = r.clientd

function reserved_value_supplier_wrapper(r::AbstractReservedValueSupplier, buffer, length)
    handler(r)(clientd(r), UnsafeArray(buffer, (Int64(length),)))
end

function reserved_value_supplier_cfunction(::T) where {T<:AbstractReservedValueSupplier}
    @cfunction(reserved_value_supplier_wrapper, Int64, (Ref{T}, Ptr{UInt8}, Csize_t))
end
