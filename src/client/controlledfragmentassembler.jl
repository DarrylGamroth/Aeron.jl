"""
    struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler

Represents a controlled fragment assembler that reassembles fragmented messages and passes them to a controlled fragment handler.

# Constructor

- `ControlledFragmentAssembler(fragment_handler::T)`: Creates a new `ControlledFragmentAssembler` with the given controlled fragment handler.
"""
mutable struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler
    fragment_handler::Base.RefValue{T}
    assembler::Ptr{aeron_controlled_fragment_assembler_t}

    function ControlledFragmentAssembler(fragment_handler::T) where {T}
        f = new{T}(Ref(fragment_handler))
        assembler = Ref{Ptr{aeron_controlled_fragment_assembler_t}}(C_NULL)

        GC.@preserve f begin
            if aeron_controlled_fragment_assembler_create(assembler,
                on_fragment_cfunction(f.fragment_handler[]),
                f.fragment_handler) < 0
                throwerror()
            end
        end

        f.assembler = assembler[]

        finalizer(f) do f
            aeron_controlled_fragment_assembler_delete(f.assembler)
        end
    end
end

function (f::ControlledFragmentAssembler)(clientd, buffer, header)
    action = aeron_controlled_fragment_assembler_handler(clientd, buffer, length(buffer), header)
    return ControlledAction.T(Integer(action))
end

on_fragment(f::ControlledFragmentAssembler) = f
clientd(f::ControlledFragmentAssembler) = f.assembler
