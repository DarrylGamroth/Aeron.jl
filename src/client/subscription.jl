struct ImageCallback
    func::Function
    client::Client
end

struct ImageViewCallback
    func::Function
end

struct Subscription
    subscription::Ptr{aeron_subscription_t}
    constants::aeron_subscription_constants_t
    client::Client
    is_owned::Bool
    on_available_image::Any
    on_unavailable_image::Any

    """
    Create a new Subscription object.

    # Arguments
    - `subscription::Ptr{aeron_subscription_t}`: Pointer to the Aeron subscription.
    - `is_owned::Bool=false`: Indicates if the subscription is owned by this instance.
    """
    function Subscription(subscription::Ptr{aeron_subscription_t}, client::Client, is_owned::Bool=false;
        on_available_image=nothing,
        on_unavailable_image=nothing)
        constants = Ref{aeron_subscription_constants_t}()
        if aeron_subscription_constants(subscription, constants) < 0
            throwerror()
        end
        return new(subscription, constants[], client, is_owned, on_available_image, on_unavailable_image)
    end
end

Base.cconvert(::Type{Ptr{aeron_subscription_t}}, s::Subscription) = s
Base.unsafe_convert(::Type{Ptr{aeron_subscription_t}}, s::Subscription) = s.subscription

function available_image_handler_wrapper(callback::ImageCallback, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    callback.func(Image(image; subscription=subscription, client=callback.client))
    nothing
end

function available_image_handler_cfunction(::T) where {T}
    @cfunction(available_image_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
end

function unavailable_image_handler_wrapper(callback::ImageCallback, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    callback.func(Image(image; subscription=subscription, client=callback.client))
    nothing
end

function unavailable_image_handler_cfunction(::T) where {T}
    @cfunction(unavailable_image_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
end

function available_image_view_handler_wrapper(callback::ImageViewCallback, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    callback.func(ImageView(image, subscription))
    nothing
end

function available_image_view_handler_cfunction(::T) where {T}
    @cfunction(available_image_view_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
end

function unavailable_image_view_handler_wrapper(callback::ImageViewCallback, subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})
    callback.func(ImageView(image, subscription))
    nothing
end

function unavailable_image_view_handler_cfunction(::T) where {T}
    @cfunction(unavailable_image_view_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_subscription_t}, Ptr{aeron_image_t}))
end

struct AsyncAddSubscription
    async::Ptr{aeron_async_add_subscription_t}
    client::Client
    on_available_image::Any
    on_unavailable_image::Any
end

"""
    async_add_subscription(c::Client, uri::AbstractString, stream_id;
                           on_available_image::Union{Nothing, Function}=nothing,
                           on_unavailable_image::Union{Nothing, Function}=nothing) -> AsyncAddSubscription

Add a subscription asynchronously.

# Arguments
- `c::Client`: The client object.
- `uri::AbstractString`: The URI of the subscription.
- `stream_id`: The stream ID of the subscription.
- `on_available_image::Union{Nothing, Function}`: Optional callback for when an image becomes available.
- `on_unavailable_image::Union{Nothing, Function}`: Optional callback for when an image becomes unavailable.

# Returns
- `AsyncAddSubscription`: The asynchronous add subscription object.
"""
function async_add_subscription(c::Client, uri::AbstractString, stream_id;
    on_available_image::Union{Nothing,Function}=nothing,
    on_unavailable_image::Union{Nothing,Function}=nothing)

    async = Ref{Ptr{aeron_async_add_subscription_t}}(C_NULL)
    available_cb = on_available_image === nothing ? nothing : Ref(ImageCallback(on_available_image, c))
    unavailable_cb = on_unavailable_image === nothing ? nothing : Ref(ImageCallback(on_unavailable_image, c))

    GC.@preserve available_cb unavailable_cb begin
        if aeron_async_add_subscription(async, c.client, uri, stream_id,
            available_cb === nothing ? C_NULL : available_image_handler_cfunction(available_cb[]),
            available_cb === nothing ? C_NULL : available_cb,
            unavailable_cb === nothing ? C_NULL : unavailable_image_handler_cfunction(unavailable_cb[]),
            unavailable_cb === nothing ? C_NULL : unavailable_cb) < 0
            throwerror()
        end
    end
    return AsyncAddSubscription(async[], c, available_cb, unavailable_cb)
end

"""
    async_add_subscription_view(c::Client, uri::AbstractString, stream_id;
                                on_available_image::Union{Nothing,Function}=nothing,
                                on_unavailable_image::Union{Nothing,Function}=nothing) -> AsyncAddSubscription

Add a subscription asynchronously and receive `ImageView` values in the image callbacks.
The view is only valid for the duration of the callback and must not be retained.
"""
function async_add_subscription_view(c::Client, uri::AbstractString, stream_id;
    on_available_image::Union{Nothing,Function}=nothing,
    on_unavailable_image::Union{Nothing,Function}=nothing)

    async = Ref{Ptr{aeron_async_add_subscription_t}}(C_NULL)
    available_cb = on_available_image === nothing ? nothing : Ref(ImageViewCallback(on_available_image))
    unavailable_cb = on_unavailable_image === nothing ? nothing : Ref(ImageViewCallback(on_unavailable_image))

    GC.@preserve available_cb unavailable_cb begin
        if aeron_async_add_subscription(async, c.client, uri, stream_id,
            available_cb === nothing ? C_NULL : available_image_view_handler_cfunction(available_cb[]),
            available_cb === nothing ? C_NULL : available_cb,
            unavailable_cb === nothing ? C_NULL : unavailable_image_view_handler_cfunction(unavailable_cb[]),
            unavailable_cb === nothing ? C_NULL : unavailable_cb) < 0
            throwerror()
        end
    end
    return AsyncAddSubscription(async[], c, available_cb, unavailable_cb)
end

"""
    poll(a::AsyncAddSubscription) -> Union{Nothing, Subscription}

Poll the status of an asynchronous add subscription request.

# Arguments
- `a::AsyncAddSubscription`: The asynchronous add subscription object.

# Returns
- `Union{Nothing, Subscription}`: The subscription object if available, `nothing` otherwise.
"""
function poll(a::AsyncAddSubscription)
    subscription = Ref{Ptr{aeron_subscription_t}}(C_NULL)
    if aeron_async_add_subscription_poll(subscription, a.async) < 0
        throwerror()
    end
    if subscription[] == C_NULL
        return nothing
    end
    return Subscription(subscription[], a.client, true;
        on_available_image=a.on_available_image,
        on_unavailable_image=a.on_unavailable_image)
end

"""
    add_subscription(c::Client, uri::AbstractString, stream_id;
                     on_available_image::Union{Nothing,Function}=nothing,
                     on_unavailable_image::Union{Nothing,Function}=nothing) -> Subscription

Add a subscription and wait for it to be available.

# Arguments
- `c::Client`: The client object.
- `uri::AbstractString`: The URI of the subscription.
- `stream_id`: The stream ID of the subscription.
- `on_available_image::Union{Nothing,Function}`: Optional callback for when an image becomes available.
- `on_unavailable_image::Union{Nothing,Function}`: Optional callback for when an image becomes unavailable.

# Returns
- `Subscription`: The subscription object.
"""
function add_subscription(c::Client, uri::AbstractString, stream_id;
    on_available_image::Union{Nothing,Function}=nothing,
    on_unavailable_image::Union{Nothing,Function}=nothing)

    async = async_add_subscription(c, uri, stream_id;
        on_available_image=on_available_image, on_unavailable_image=on_unavailable_image)
    while true
        subscription = poll(async)
        if subscription !== nothing
            return subscription
        end
        yield()
    end
end

"""
    add_subscription_view(c::Client, uri::AbstractString, stream_id;
                          on_available_image::Union{Nothing,Function}=nothing,
                          on_unavailable_image::Union{Nothing,Function}=nothing) -> Subscription

Add a subscription and wait for it to be available, using `ImageView` values in callbacks.
The view is only valid for the duration of each callback and must not be retained.
"""
function add_subscription_view(c::Client, uri::AbstractString, stream_id;
    on_available_image::Union{Nothing,Function}=nothing,
    on_unavailable_image::Union{Nothing,Function}=nothing)

    async = async_add_subscription_view(c, uri, stream_id;
        on_available_image=on_available_image, on_unavailable_image=on_unavailable_image)
    while true
        subscription = poll(async)
        if subscription !== nothing
            return subscription
        end
        yield()
    end
end

"""
    async_add_destination(s::Subscription, uri::AbstractString) -> AsyncDestination

Add a destination to a subscription asynchronously.

# Arguments
- `s::Subscription`: The subscription object.
- `uri::AbstractString`: The URI of the destination.

# Returns
- `AsyncDestination`: The asynchronous destination object.
"""
function async_add_destination(s::Subscription, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_subscription_async_add_destination(async, pointer(s.client), s.subscription, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
    add_destination(s::Subscription, uri::AbstractString)

Add a destination to a subscription and wait for it to be available.

# Arguments
- `s::Subscription`: The subscription object.
- `uri::AbstractString`: The URI of the destination.
"""
function add_destination(s::Subscription, uri::AbstractString)
    async = async_add_destination(s, uri)
    while true
        poll(s, async) && return
        yield()
    end
end

"""
    async_remove_destination(s::Subscription, uri::AbstractString) -> AsyncDestination

Remove a destination from a subscription asynchronously.

# Arguments
- `s::Subscription`: The subscription object.
- `uri::AbstractString`: The URI of the destination.

# Returns
- `AsyncDestination`: The asynchronous destination object.
"""
function async_remove_destination(s::Subscription, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_subscription_async_remove_destination(async, pointer(s.client), s.subscription, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
    remove_destination(s::Subscription, uri::AbstractString)

Remove a destination from a subscription and wait for it to be removed.

# Arguments
- `s::Subscription`: The subscription object.
- `uri::AbstractString`: The URI of the destination.
"""
function remove_destination(s::Subscription, uri::AbstractString)
    async = async_remove_destination(s, uri)
    while true
        poll(s, async) && return
        yield()
    end
end

"""
    poll(s::Subscription, a::AsyncDestination) -> Bool
Poll the status of an asynchronous destination request.

# Arguments
- `s::Subscription`: The subscription object.
- `a::AsyncDestination`: The asynchronous destination object.

# Returns
- `Bool`: `true` if the operation is complete, `false` otherwise.
"""
function poll(::Subscription, a::AsyncDestination)
    retval = aeron_subscription_async_destination_poll(a.async)
    if retval < 0
        throwerror()
    end
    return retval > 0
end

"""
Close a subscription.

# Arguments
- `s::Subscription`: The subscription object.
"""
function Base.close(s::Subscription)
    if s.is_owned == true
        if aeron_subscription_close(s.subscription, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
end

"""
Get the channel of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `String`: The channel of the subscription.
"""
channel(s::Subscription) = unsafe_string(s.constants.channel)

"""
Get the registration ID of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Int64`: The registration ID of the subscription.
"""
registration_id(s::Subscription) = s.constants.registration_id

"""
Get the stream ID of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Int32`: The stream ID of the subscription.
"""
stream_id(s::Subscription) = s.constants.stream_id

"""
Get the channel status indicator ID of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Int32`: The channel status indicator ID of the subscription.
"""
channel_status_indicator_id(s::Subscription) = s.constants.channel_status_indicator_id

"""
Check if the subscription is connected.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Bool`: `true` if the subscription is connected, `false` otherwise.
"""
is_connected(s::Subscription) = aeron_subscription_is_connected(s.subscription)

"""
Get the image count of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Int32`: The image count of the subscription.
"""
image_count(s::Subscription) = aeron_subscription_image_count(s.subscription)

"""
Get the channel status of the subscription.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Symbol`: The channel status of the subscription.
"""
channel_status(s::Subscription) = aeron_subscription_channel_status(s.subscription) == 1 ? :active : :errored

"""
Check if the subscription is open.

# Arguments
- `s::Subscription`: The subscription.

# Returns
- `Bool`: `true` if the subscription is open, `false` otherwise.
"""
Base.isopen(s::Subscription) = !aeron_subscription_is_closed(s.subscription)

"""
    poll(s::Subscription, fragment_handler::AbstractFragmentHandler, fragment_limit::Int32) -> Int32

Poll the images under the subscription for available message fragments.
Each fragment read will be a whole message if it is under MTU length.
If larger than MTU then it will come as a series of fragments ordered within a session.

To assemble messages that span multiple fragments then use `FragmentAssembler`.

# Arguments
- `s::Subscription`: The subscription.
- `fragment_handler::AbstractFragmentHandler`: The fragment handler.
- `fragment_limit::Int32`: The maximum number of fragments to process during this poll.

# Returns
- `Int`: The number of fragments processed.
"""
function poll(s::Subscription, fragment_handler::AbstractFragmentHandler, fragment_limit)
    GC.@preserve fragment_handler begin
        num_fragments = aeron_subscription_poll(s.subscription,
            on_fragment_cfunction(fragment_handler), Ref(fragment_handler), fragment_limit)
    end

    if num_fragments < 0
        throwerror()
    end

    return Int(num_fragments)
end

"""
    poll(s::Subscription, fragment_handler::AbstractControlledFragmentHandler, fragment_limit::Int32) -> Int32

Poll in a controlled manner the images under the subscription for available message fragments.
Control is applied to fragments in the stream. If more fragments can be read on another stream
they will even if BREAK or ABORT is returned from the fragment handler.
Each fragment read will be a whole message if it is under MTU length. If larger than MTU then it will come
as a series of fragments ordered within a session.
To assemble messages that span multiple fragments then use aeron_controlled_fragment_assembler_t.

# Arguments
- `s::Subscription`: The subscription.
- `fragment_handler::AbstractControlledFragmentHandler`: The controlled fragment handler.
- `fragment_limit::Int32`: The maximum number of fragments to process during this poll.

# Returns
- `Int`: The number of fragments processed.
"""
function poll(s::Subscription, fragment_handler::AbstractControlledFragmentHandler, fragment_limit)
    GC.@preserve fragment_handler begin
        num_fragments = aeron_subscription_controlled_poll(s.subscription,
            on_fragment_cfunction(fragment_handler), Ref(fragment_handler), fragment_limit)
    end

    if num_fragments < 0
        throwerror()
    end

    return Int(num_fragments)
end

"""
    poll(s::Subscription, block_handler::AbstractBlockHandler, block_length_limit::Int32) -> Int32

Poll the images under the subscription for available message fragments in blocks.
This method is useful for operations like bulk archiving and messaging indexing.

# Arguments
- `s::Subscription`: The subscription.
- `block_handler::AbstractBlockHandler`: The block handler.
- `block_length_limit::Int32`: The maximum number of bytes to process during this poll.

# Returns
- `Int`: The number of bytes consumed.
"""
function poll(s::Subscription, block_handler::AbstractBlockHandler, block_length_limit)
    GC.@preserve block_handler begin
        bytes = aeron_subscription_block_poll(s.subscription,
            on_block_cfunction(block_handler), Ref(block_handler), block_length_limit)
    end

    if bytes < 0
        throwerror()
    end

    return Int(bytes)
end

"""
    image_by_session_id(s::Subscription, session_id::Int32) -> Union{Nothing, Image}

Return the image associated with the given session\\_id under the given subscription.
The caller must close the returned `Image` to release it. No finalizer is used for cleanup.
"""
function image_by_session_id(s::Subscription, session_id)
    image = aeron_subscription_image_by_session_id(s.subscription, session_id)
    if image == C_NULL
        return nothing
    end
    return Image(image; subscription=s.subscription, client=s.client)
end

function image_by_session_id(f::Function, s::Subscription, session_id)
    img = image_by_session_id(s, session_id)
    if img === nothing
        return nothing
    end
    try
        f(img)
    finally
        close(img)
    end
end

"""
    image_at_index(s::Subscription, index::Int32) -> Union{Nothing, Image}

Return the image at the given index.
The caller must close the returned `Image` to release it. No finalizer is used for cleanup.
"""
function image_at_index(s::Subscription, index)
    image = aeron_subscription_image_at_index(s.subscription, index)
    if image == C_NULL
        return nothing
    end
    return Image(image; subscription=s.subscription, client=s.client)
end

function image_at_index(f::Function, s::Subscription, index)
    img = image_at_index(s, index)
    if img === nothing
        return nothing
    end
    try
        f(img)
    finally
        close(img)
    end
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
