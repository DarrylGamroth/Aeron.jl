mutable struct FragmentAssembler{T<:AbstractFragmentHandler} <: AbstractFragmentHandler
    assembler::Ptr{aeron_fragment_assembler_t}
    # Hold a reference to the FragmentHandler to prevent it from being garbage collected
    fragment_handler::T

    function FragmentAssembler(fragment_handler::T) where {T<:AbstractFragmentHandler}
        assembler = Ref{Ptr{Aeron.aeron_fragment_assembler_t}}()

        if aeron_fragment_assembler_create(assembler,
            on_fragment_cfunction(fragment_handler),
            on_fragment_clientd(fragment_handler)) < 0
            throwerror()
        end

        finalizer(new{T}(assembler[], fragment_handler)) do f
            aeron_fragment_assembler_delete(f.assembler)
        end
    end
end

on_fragment_clientd(f::FragmentAssembler) = f.assembler

function on_fragment_cfunction(::FragmentAssembler)
    @cfunction(aeron_fragment_assembler_handler, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Ptr{Cvoid}))
end
