mutable struct Subscription
    subscription::Ptr{aeron_subscription_t}
    const constants::aeron_subscription_constants_t
    const allocated::Bool
    function Subscription(subscription::Ptr{aeron_subscription_t}, allocated::Bool=false)
        constants = Ref{aeron_subscription_constants_t}()
        if aeron_subscription_constants(subscription, constants) < 0
            throwerror()
        end
        finalizer(close, new(subscription, constants[], allocated))
    end
end

function available_image_handler_wrapper(clientd::Context, ::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    clientd.available_image_handler(clientd, Image(image))
end

function unavailable_image_handler_wrapper(clientd::Context, ::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    clientd.unavailable_image_handler(clientd, Image(image))
end

struct AsyncAddSubscription
    async::Ptr{aeron_async_add_subscription_t}
end

function async_add_subscription(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_subscription_t}}(C_NULL)

    available_image_func = @cfunction(available_image_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
    unavailable_image_func = @cfunction(unavailable_image_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))

    if aeron_async_add_subscription(async, c.client, uri, stream_id,
        available_image_func, Ref(context(c)),
        unavailable_image_func, Ref(context(c))) < 0
        throwerror()
    end
    return AsyncAddSubscription(async[])
end

function poll(a::AsyncAddSubscription)
    subscription = Ref{Ptr{aeron_subscription_t}}(C_NULL)
    if aeron_async_add_subscription_poll(subscription, a.async) < 0
        throwerror()
    end
    if subscription[] == C_NULL
        return nothing
    end
    return Subscription(subscription[], true)
end

function add_subscription(c::Client, uri::AbstractString, stream_id)
    async = async_add_subscription(c, uri, stream_id)
    while true
        subscription = poll(async)
        if subscription !== nothing
            return subscription
        end
        yield()
    end
end

function async_add_destination(c::Client, s::Subscription, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_subscription_async_add_destination(async, c.client, s.subscription, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function async_remove_destination(c::Client, s::Subscription, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_subscription_async_remove_destination(async, c.client, s.subscription, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function poll(::Subscription, a::AsyncDestination)
    destination = Ref{Ptr{aeron_destination_t}}(C_NULL)
    retval = aeron_subscription_async_destination_poll(destination, a.async) < 0
    if retval < 0
        throwerror()
    end
    return retval > 0
end

function Base.close(s::Subscription)
    if s.allocated == true
        if aeron_subscription_close(s.subscription, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
    s.subscription = C_NULL
end

channel(s::Subscription) = unsafe_string(s.constants.channel)
registration_id(s::Subscription) = s.constants.registration_id
stream_id(s::Subscription) = s.constants.stream_id
channel_status_indicator_id(s::Subscription) = s.constants.channel_status_indicator_id
is_connected(s::Subscription) = aeron_subscription_is_connected(s.subscription)
image_count(s::Subscription) = aeron_subscription_image_count(s.subscription)

channel_status(s::Subscription) = aeron_publication_channel_status(s.subscription) == 1 ? :active : :errored
Base.isopen(s::Subscription) = !aeron_subscription_is_closed(s.subscription)
is_connected(s::Subscription) = aeron_subscription_is_connected(s.subscription)

function poll(s::Subscription, fragment_handler::AbstractFragmentHandler, fragment_limit)
    num_fragments = aeron_subscription_poll(s.subscription,
        on_fragment_cfunction(fragment_handler), on_fragment_clientd(fragment_handler), fragment_limit)

    if num_fragments < 0
        throwerror()
    end

    return num_fragments
end

function poll(s::Subscription, fragment_handler::AbstractControlledFragmentHandler, fragment_limit)
    num_fragments = aeron_subscription_controlled_poll(s.subscription,
        on_fragment_cfunction(fragment_handler), on_fragment_clientd(fragment_handler), fragment_limit)

    if num_fragments < 0
        throwerror()
    end

    return num_fragments
end

function poll(s::Subscription, block_handler::AbstractBlockHandler, block_length_limit)
    bytes = aeron_subscription_block_poll(s.subscription,
        on_fragment_cfunction(block_handler), on_fragment_clientd(block_handler), block_length_limit)

    if bytes < 0
        throwerror()
    end

    return bytes
end

function Base.show(io::IO, ::MIME"text/plain", s::Subscription)
    println(io, "Subscription")
    println(io, "  channel: ", channel(s))
    println(io, "  registration_id: ", registration_id(s))
    println(io, "  stream_id: ", stream_id(s))
    println(io, "  channel_status_indicator_id: ", channel_status_indicator_id(s))
    println(io, "  is connected: ", is_connected(s))
    println(io, "  image count: ", image_count(s))
    println(io, "  channel status: ", channel_status(s))
    println(io, "  is open: ", isopen(s))
end
