"""
    struct FragmentAssembler{T<:AbstractFragmentHandler} <: AbstractFragmentHandler

Represents a fragment assembler that reassembles fragmented messages and passes them to a fragment handler.

# Constructor

- `FragmentAssembler(on_fragment::T)`: Creates a new `FragmentAssembler` with the given fragment handler.
"""
mutable struct FragmentAssembler{T<:Function,C,F<:AbstractFragmentHandler} <: AbstractFragmentHandler
    on_fragment::T
    clientd::C
    fragment_handler::F
end

on_fragment(f::FragmentAssembler) = f.on_fragment
clientd(f::FragmentAssembler) = f.clientd

function FragmentAssembler(fragment_handler::AbstractFragmentHandler)
    assembler = Ref{Ptr{aeron_fragment_assembler_t}}(C_NULL)

    if aeron_fragment_assembler_create(assembler,
        on_fragment_cfunction(fragment_handler),
        Ref(fragment_handler)) < 0
        throwerror()
    end

    fa = FragmentAssembler(assembler[], fragment_handler) do clientd, buffer, header
        aeron_fragment_assembler_handler(clientd, buffer, length(buffer), header_ptr(header))
    end

    finalizer(fa) do fa
        aeron_fragment_assembler_delete(fa.clientd)
    end
end
