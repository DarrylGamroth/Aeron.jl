"""
    struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler

Represents a controlled fragment assembler that reassembles fragmented messages and passes them to a controlled fragment handler.

# Constructor

- `ControlledFragmentAssembler(on_fragment::T)`: Creates a new `ControlledFragmentAssembler` with the given controlled fragment handler.
"""
mutable struct ControlledFragmentAssembler{T,C,F<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler
    on_fragment::T
    clientd::C
    fragment_handler::F
end

on_fragment(f::ControlledFragmentAssembler) = f.on_fragment
clientd(f::ControlledFragmentAssembler) = f.clientd

function ControlledFragmentAssembler(fragment_handler::AbstractControlledFragmentHandler)
    assembler = Ref{Ptr{aeron_controlled_fragment_assembler_t}}(C_NULL)

    if aeron_controlled_fragment_assembler_create(assembler,
        on_fragment_cfunction(fragment_handler),
        Ref(fragment_handler)) < 0
        throwerror()
    end

    fa = ControlledFragmentAssembler(assembler[], fragment_handler) do clientd, buffer, header
        action = aeron_controlled_fragment_assembler_handler(clientd, buffer, length(buffer), pointer(header))
        return ControlledAction.T(Integer(action))
    end

    finalizer(fa) do fa
        aeron_controlled_fragment_assembler_delete(fa.clientd)
    end
end
