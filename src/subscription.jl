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

function add_subscription(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_subscription_t}}(C_NULL)
    subscription = Ref{Ptr{aeron_subscription_t}}(C_NULL)

    available_image_func = @cfunction(available_image_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
    unavailable_image_func = @cfunction(unavailable_image_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))

    try
        if aeron_async_add_subscription(async, c.client, uri, stream_id,
            available_image_func, Ref(context(c)),
            unavailable_image_func, Ref(context(c))) < 0
            throwerror()
        end

        while subscription[] == C_NULL
            if aeron_async_add_subscription_poll(subscription, async[]) < 0
                throwerror()
            end
            yield()
        end
        return Subscription(subscription[], true)
    catch e
        if subscription[] != C_NULL
            aeron_subscription_close(subscription[], C_NULL, C_NULL)
        end
        throw(e)
    end
end

function Base.close(s::Subscription)
    if s.allocated == true
        if aeron_subscription_close(s.subscription, C_NULL, C_NULL) < 0
            throwerror()
        end
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
    num_fragments = aeron_subscription_poll(s.subscription,
        on_fragment_cfunction(fragment_handler), on_fragment_clientd(fragment_handler), fragment_limit)

    if num_fragments < 0
        throwerror()
    end

    return num_fragments
end
