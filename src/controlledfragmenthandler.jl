abstract type AbstractControlledFragmentHandler end

@enumx ControlledAction begin
    ABORT = 1
    BREAK = 2
    COMMIT = 3
    CONTINUE = 4
end

mutable struct ControlledFragmentHandler{T<:Function,C} <: AbstractControlledFragmentHandler
    on_fragment_handler::T
    clientd::C
    function ControlledFragmentHandler(on_fragment_handler::T, clientd::C=nothing) where {T<:Function, C}
        new{T, C}(on_fragment_handler, clientd)
    end
end

function on_fragment_wrapper(f::AbstractControlledFragmentHandler, buffer, length, header)
    action = f.on_fragment_handler(f.clientd, UnsafeArray(buffer, (Int64(length),)), Header(header))

    return action == ControlledAction.ABORT ? AERON_ACTION_ABORT :
           action == ControlledAction.BREAK ? AERON_ACTION_BREAK :
           action == ControlledAction.COMMIT ? AERON_ACTION_COMMIT :
           action == ControlledAction.CONTINUE ? AERON_ACTION_CONTINUE :
           throw(ArgumentError("Unknown action: $action"))
end

on_fragment_clientd(f::ControlledFragmentHandler) = Ref(f)

function on_fragment_cfunction(::T) where {T<:AbstractControlledFragmentHandler}
    @cfunction(on_fragment_wrapper,
        aeron_controlled_fragment_handler_action_t,
        (Ref{T}, Ptr{UInt8}, Csize_t, Ptr{aeron_header_t}))
end
