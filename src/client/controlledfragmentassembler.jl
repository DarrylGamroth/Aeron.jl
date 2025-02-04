"""
    struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler

Represents a controlled fragment assembler that reassembles fragmented messages and passes them to a controlled fragment handler.

# Constructor

- `ControlledFragmentAssembler(fragment_handler::T)`: Creates a new `ControlledFragmentAssembler` with the given controlled fragment handler.
"""
mutable struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler
    fragment_handler::T
    assembler::Ptr{aeron_controlled_fragment_assembler_t}

    function ControlledFragmentAssembler(fragment_handler::T) where {T}
        assembler = Ref{Ptr{aeron_controlled_fragment_assembler_t}}(C_NULL)

        GC.@preserve fragment_handler begin
            if aeron_controlled_fragment_assembler_create(assembler,
                on_fragment_cfunction(fragment_handler),
                Ref(fragment_handler)) < 0
                throwerror()
            end
        end

        finalizer(new{T}(fragment_handler, assembler[])) do f
            aeron_controlled_fragment_assembler_delete(f.assembler)
        end
    end
end

function (f::ControlledFragmentAssembler)(clientd, buffer, header)
    action = aeron_controlled_fragment_assembler_handler(clientd, buffer, length(buffer), pointer(header))
    return ControlledAction.T(Integer(action))
end

on_fragment(f::ControlledFragmentAssembler) = f
clientd(f::ControlledFragmentAssembler) = f.assembler
