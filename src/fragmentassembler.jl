abstract type AbstractFragmentHandler end

using FunctionWrappers
import FunctionWrappers: FunctionWrapper
const FragmentHandlerDelegate = FunctionWrapper{Nothing,Tuple{AbstractVector{UInt8},Header}}

mutable struct FragmentAssembler <: AbstractFragmentHandler
    assembler::Ptr{aeron_fragment_assembler_t}
    delegate::FragmentHandlerDelegate
end

mutable struct FragmentHandler <: AbstractFragmentHandler
    delegate::FragmentHandlerDelegate
end

function delete(f::FragmentAssembler)
    ccall(:jl_safe_printf, Cvoid, (Cstring, Cstring), "Finalizing %s.\n", repr(f))
    aeron_fragment_assembler_delete(f.assembler)
end
# function onfragment(f::FragmentAssembler, buffer::AbstractArray{UInt8}, header::Header)
#     aeron_fragment_assembler_handler(f, buffer, length(buffer), header.header)
# end

# function fragment_handler_wrapper(clientd::Ptr{FragmentHandler}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})
#     # assembler = unsafe_unsafe_pointer_to_objref(clientd)::FragmentAssembler
#     # onfragment(assembler, UnsafeArray(buffer, (Int64(length),)), Header(header))
#     nothing
# end

# function handler(::FragmentAssembler)
#     @cfunction(fragment_handler_wrapper, Cvoid, (Ptr{FragmentHandler}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
# end

function fragment_assembler_handler_wrapper(clientd::Ptr{FragmentHandler}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})
    # assembler = unsafe_pointer_to_objref(clientd)::FragmentAssembler
    # assembler.delegate(UnsafeArray(buffer, (Int64(length),)), Header(header))
    nothing
end

function FragmentAssembler(delegate::FragmentHandlerDelegate)
    f = FragmentAssembler(C_NULL, delegate)
    handler = @cfunction(fragment_assembler_handler_wrapper, Cvoid, (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))

    fragment_assembler = Ref{Ptr{aeron_fragment_assembler_t}}(C_NULL)
    if aeron_fragment_assembler_create(fragment_assembler, handler, pointer_from_objref(f)) < 0
        throwerror()
    end
    f.assembler = fragment_assembler[]
    finalizer(delete, f)
end

function handler(::FragmentAssembler)
    @cfunction(aeron_fragment_assembler_handler, Cvoid, (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end

################

function fragment_handler_wrapper(clientd::Ptr{Cvoid}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})
    f = unsafe_pointer_to_objref(clientd)::FragmentHandler
    f.delegate(UnsafeArray(buffer, (Int64(length),)), Header(header))
    nothing
end

function handler(::FragmentHandler)
    @cfunction(fragment_handler_wrapper, Cvoid, (Ptr{Cvoid}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end

