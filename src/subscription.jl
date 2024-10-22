mutable struct Subscription
    subscription::Ptr{aeron_subscription_t}
    const constants::aeron_subscription_constants_t
    function Subscription(subscription::Ptr{aeron_subscription_t})
        constants = Ref{aeron_subscription_constants_t}()
        if aeron_subscription_constants(subscription, constants) < 0
            throwerror()
        end
        finalizer(close, new(subscription, constants[]))
        # new(subscription, constants[])
    end
end

# typedef void ( * aeron_fragment_handler_t ) ( void * clientd , const uint8_t * buffer , size_t length , aeron_header_t * header )
"""
Callback for handling fragments of data being read from a log.

The frame will either contain a whole message or a fragment of a message to be reassembled. Messages are fragmented if greater than the frame for MTU in length.

# Arguments
* `clientd`: passed to the poll function.
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
"""
# const fragment_handler = @cfunction(aeron_fragment_handler, Cvoid, (Ptr{Cvoid}, Ptr{UInt8}, Int32, Ptr{aeron_header_t}))

function available_image_handler_wrapper(clientd::Ptr{Cvoid}, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    client = unsafe_pointer_to_objref(clientd)::Client
    client.available_image_handler(client, Image(image))
end

function unavailable_image_handler_wrapper(clientd::Ptr{Cvoid}, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    client = unsafe_pointer_to_objref(clientd)::Client
    client.unavailable_image_handler(client, Image(image))
end

function add_subscription(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_subscription_t}}(C_NULL)
    subscription = Ref{Ptr{aeron_subscription_t}}(C_NULL)

    available_image_func = @cfunction(available_image_handler_wrapper, Cvoid, (Ptr{Cvoid}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
    unavailable_image_func = @cfunction(unavailable_image_handler_wrapper, Cvoid, (Ptr{Cvoid}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))

    try
        if aeron_async_add_subscription(async, c.client, uri, stream_id,
            available_image_func, pointer_from_objref(c),
            unavailable_image_func, pointer_from_objref(c)) < 0
            throwerror()
        end

        while subscription[] == C_NULL
            if aeron_async_add_subscription_poll(subscription, async[]) < 0
                throwerror()
            end
            yield()
        end
        return Subscription(subscription[])
    catch e
        if subscription[] != C_NULL
            aeron_subscription_close(subscription[], C_NULL, C_NULL)
        end
        throw(e)
    end
end

function Base.close(s::Subscription)
    ccall(:jl_safe_printf, Cvoid, (Cstring, Cstring), "Finalizing %s.\n", repr(s))
    if aeron_subscription_close(s.subscription, C_NULL, C_NULL) < 0
        throwerror()
    end
end

channel(s::Subscription) = unsafe_string(s.constants.channel)
registration_id(s::Subscription) = s.constants.registration_id
stream_id(s::Subscription) = s.constants.stream_id
channel_status_indicator_id(s::Subscription) = s.constants.channel_status_indicator_id
isconnected(s::Subscription) = aeron_subscription_is_connected(s.subscription)
image_count(s::Subscription) = aeron_subscription_image_count(s.subscription)

channel_status(s::Subscription) = aeron_publication_channel_status(s.subscription) == 1 ? :active : :errored
Base.isopen(s::Subscription) = !aeron_subscription_is_closed(s.subscription)
isconnected(s::Subscription) = aeron_subscription_is_connected(s.subscription)

function poll(s::Subscription, fragment_handler::AbstractFragmentHandler, fragment_limit)
    num_fragments = aeron_subscription_poll(s.subscription, handler(fragment_handler), pointer_from_objref(fragment_handler), fragment_limit)
    # num_fragments = @ccall Aeron_jll.libaeron.aeron_subscription_poll(s.subscription::Ptr{aeron_subscription_t}, handler(fragment_handler)::aeron_fragment_handler_t, fragment_handler::FragmentHandler, fragment_limit::Csize_t)::Cint

    if num_fragments < 0
        throwerror()
    end
    return num_fragments
end
