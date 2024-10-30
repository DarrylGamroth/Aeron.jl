abstract type AbstractReservedValueSupplier end

mutable struct ReservedValueSupplier{T<:Function, C} <: AbstractReservedValueSupplier
    reserved_value_supplier_handler::T
    clientd::C
    function ReservedValueSupplier(reserved_value_supplier_handler::T, clientd::C=nothing) where {T<:Function, C}
        new{T, C}(reserved_value_supplier_handler, clientd)
    end
end

function reserved_value_supplier_wrapper(r::AbstractReservedValueSupplier, buffer, length)
    r.reserved_value_supplier_handler(r.clientd, UnsafeArray(buffer, (Int64(length),)))
end

reserved_value_supplier_clientd(r::ReservedValueSupplier) = Ref(r)

function reserved_value_supplier_cfunction(::T) where {T<:AbstractReservedValueSupplier}
    @cfunction(reserved_value_supplier_wrapper, Int64, (Ref{T}, Ptr{UInt8}, Csize_t))
end
