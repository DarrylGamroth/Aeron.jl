"""
    struct FragmentAssembler{T<:AbstractFragmentHandler} <: AbstractFragmentHandler

Represents a fragment assembler that reassembles fragmented messages and passes them to a fragment handler.

# Constructor

- `FragmentAssembler(fragment_handler::T)`: Creates a new `FragmentAssembler` with the given fragment handler.
"""
mutable struct FragmentAssembler{T<:AbstractFragmentHandler} <: AbstractFragmentHandler
    fragment_handler::T
    assembler::Ptr{aeron_fragment_assembler_t}

    function FragmentAssembler(fragment_handler::T) where {T}
        assembler = Ref{Ptr{aeron_fragment_assembler_t}}(C_NULL)

        if aeron_fragment_assembler_create(assembler,
            on_fragment_cfunction(fragment_handler),
            Ref(fragment_handler)) < 0
            throwerror()
        end

        finalizer(new{T}(fragment_handler, assembler[])) do f
            aeron_fragment_assembler_delete(f.assembler)
        end
    end
end

function (f::FragmentAssembler)(clientd, buffer, header)
    aeron_fragment_assembler_handler(clientd, buffer, length(buffer), pointer(header))
end

on_fragment(f::FragmentAssembler) = f
clientd(f::FragmentAssembler) = f.assembler
