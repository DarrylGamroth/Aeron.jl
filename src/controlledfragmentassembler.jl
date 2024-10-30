mutable struct ControlledFragmentAssembler{T<:AbstractControlledFragmentHandler} <: AbstractControlledFragmentHandler
    assembler::Ptr{aeron_controlled_fragment_assembler_t}
    # Hold a reference to the FragmentHandler to prevent it from being garbage collected
    fragment_handler::T

    function ControlledFragmentAssembler(fragment_handler::T) where {T<:AbstractControlledFragmentHandler}
        assembler = Ref{Ptr{aeron_controlled_fragment_assembler_t}}(C_NULL)

        if aeron_controlled_fragment_assembler_create(assembler,
            on_fragment_cfunction(fragment_handler),
            on_fragment_clientd(fragment_handler)) < 0
            throwerror()
        end

        finalizer(new{T}(assembler[], fragment_handler)) do f
            aeron_controlled_fragment_assembler_delete(f.assembler)
        end
    end
end

on_fragment_clientd(f::ControlledFragmentAssembler) = f.assembler

function on_fragment_cfunction(::ControlledFragmentAssembler)
    @cfunction(aeron_controlled_fragment_assembler_handler,
        aeron_controlled_fragment_handler_action_t,
        (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Ptr{Cvoid}))
end
