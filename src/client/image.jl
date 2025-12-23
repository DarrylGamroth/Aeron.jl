"""
    struct Image

Represents an Aeron image, which is a stream of messages from a publication.

# Fields

- `image::Ptr{aeron_image_t}`: Pointer to the underlying Aeron image structure.
- `constants::aeron_image_constants_t`: Constants associated with the image.

# Constructor

- `Image(image::Ptr{aeron_image_t})`: Creates a new `Image` instance with the given Aeron image pointer.
"""
mutable struct Image
    image::Ptr{aeron_image_t}
    constants::aeron_image_constants_t
    subscription::Ptr{aeron_subscription_t}
    client::Any
    released::Bool

    function Image(image::Ptr{aeron_image_t};
        subscription::Ptr{aeron_subscription_t}=C_NULL,
        client=nothing)
        constants = Ref{aeron_image_constants_t}()
        if aeron_image_constants(image, constants) < 0
            throwerror()
        end
        new(image, constants[], subscription, client, false)
    end
end

function _cstring_len(ptr::Cstring)
    return ccall(:strlen, Csize_t, (Cstring,), ptr)
end

function _cstring_view(ptr::Cstring)
    if ptr == C_NULL
        return StringView(UnsafeArray(Ptr{UInt8}(C_NULL), (0,)))
    end
    return StringView(UnsafeArray(Ptr{UInt8}(ptr), (Int(_cstring_len(ptr)),)))
end

"""
    struct ImageView

Non-allocating view into an Aeron image. The view is only valid for the duration
of the callback that created it and must not be retained.
"""
struct ImageView
    image::Ptr{aeron_image_t}
    subscription::Ptr{aeron_subscription_t}
    constants::aeron_image_constants_t

    function ImageView(image::Ptr{aeron_image_t}, subscription::Ptr{aeron_subscription_t})
        constants = Ref{aeron_image_constants_t}()
        if aeron_image_constants(image, constants) < 0
            throwerror()
        end
        new(image, subscription, constants[])
    end
end

Base.cconvert(::Type{Ptr{aeron_image_t}}, i::Image) = i
Base.unsafe_convert(::Type{Ptr{aeron_image_t}}, i::Image) = i.image

"""
    subscription(i::Image) -> Subscription

Returns the `Subscription` associated with the `Image` `i`.
"""
function subscription(i::Image)
    if !(i.client isa Client)
        error("Image does not have an associated client; create it via a Subscription or pass client=... to Image")
    end
    if i.subscription == C_NULL
        error("Image is not associated with a Subscription")
    end
    return Subscription(i.subscription, i.client, false)
end

"""
    subscription(view::ImageView, client::Client) -> Subscription

Construct a `Subscription` from an `ImageView` using the provided client.
"""
function subscription(view::ImageView, client)
    if !(client isa Client)
        error("Expected a Client to construct a Subscription from an ImageView")
    end
    if view.subscription == C_NULL
        error("ImageView is not associated with a Subscription")
    end
    return Subscription(view.subscription, client, false)
end

"""
    source_identity(i::Image) -> String

Returns the source identity of the `Image` `i`.

The source identity is a string that identifies the source of the image.
"""
source_identity(i::Image) = unsafe_string(i.constants.source_identity)
source_identity(view::ImageView) = _cstring_view(view.constants.source_identity)

"""
    correlation_id(i::Image) -> Int64

Returns the correlation ID of the `Image` `i`.

The correlation ID is a unique identifier for the image.
"""
correlation_id(i::Image) = i.constants.correlation_id
correlation_id(view::ImageView) = view.constants.correlation_id

"""
    join_position(i::Image) -> Int64

Returns the join position of the `Image` `i`.

The join position is the position in the stream where the image was joined.
"""
join_position(i::Image) = i.constants.join_position
join_position(view::ImageView) = view.constants.join_position

"""
    position_bits_to_shift(i::Image) -> Int32

Returns the number of bits to shift for the position of the `Image` `i`.

This value is used for calculating the position within the term buffer.
"""
position_bits_to_shift(i::Image) = i.constants.position_bits_to_shift
position_bits_to_shift(view::ImageView) = view.constants.position_bits_to_shift

"""
    term_buffer_length(i::Image) -> Int32

Returns the length of the term buffer for the `Image` `i`.

The term buffer length is the size of the buffer used for storing messages.
"""
term_buffer_length(i::Image) = i.constants.term_buffer_length
term_buffer_length(view::ImageView) = view.constants.term_buffer_length

"""
    mtu_length(i::Image) -> Int32

Returns the Maximum Transmission Unit (MTU) length for the `Image` `i`.

The MTU length is the maximum size of a message that can be transmitted.
"""
mtu_length(i::Image) = i.constants.mtu_length
mtu_length(view::ImageView) = view.constants.mtu_length

"""
    session_id(i::Image) -> Int32

Returns the session ID of the `Image` `i`.

The session ID is a unique identifier for the session associated with the image.
"""
session_id(i::Image) = i.constants.session_id
session_id(view::ImageView) = view.constants.session_id

"""
    initial_term_id(i::Image) -> Int32

Returns the initial term ID of the `Image` `i`.

The initial term ID is the ID of the first term in the stream.
"""
initial_term_id(i::Image) = i.constants.initial_term_id
initial_term_id(view::ImageView) = view.constants.initial_term_id

"""
    subscriber_position_id(i::Image) -> Int32

Returns the subscriber position ID of the `Image` `i`.

The subscriber position ID is the ID of the position of the subscriber in the stream.
"""
subscriber_position_id(i::Image) = i.constants.subscriber_position_id
subscriber_position_id(view::ImageView) = view.constants.subscriber_position_id

"""
    Base.isopen(i::Image) -> Bool

Returns `true` if the `Image` `i` is open, `false` otherwise.

An image is considered open if it has not been closed.
"""
Base.isopen(i::Image) = !aeron_image_is_closed(i.image)

"""
    position(i::Image) -> Int64

Returns the position of the `Image` `i`.

The position this image has been consumed to by the subscriber.
"""
position(i::Image) = aeron_image_position(i.image)

"""
    position!(i::Image, value::Int64)

Set the subscriber position for this image to indicate where it has been consumed to.
"""
function position!(i::Image, value::Int64)
    retval = aeron_image_set_position(i.image, value)
    if retval < 0
        throwerror()
    end
end

"""
    is_end_of_stream(i::Image) -> Bool

Is the current consumed position at the end of the stream?
"""
is_end_of_stream(i::Image) = aeron_image_is_end_of_stream(i.image)

"""
    end_of_stream_position(i::Image) -> Int64

The position the stream reached when EOS was received from the publisher. The position will be INT64\\_MAX until the stream ends and EOS is set.
"""
end_of_stream_position(i::Image) = aeron_image_end_of_stream_position(i.image)

"""
    active_transport_count(i::Image) -> Int32

Count of observed active transports within the image liveness timeout.

# Returns
Count of active transports - 0 if Image is closed, no datagrams yet, or IPC.
"""
function active_transport_count(i::Image)
    retval = aeron_image_active_transport_count(i.image)
    if retval < 0
        throwerror()
    end
    return retval
end

"""
    is_publication_revoked(i::Image) -> Bool

Has the publication for this image been revoked?
"""
is_publication_revoked(i::Image) = aeron_image_is_publication_revoked(i.image)

"""
    close(i::Image)

Release the image back to the subscription.
"""
function Base.close(i::Image)
    if i.released
        return
    end
    if i.subscription != C_NULL
        retval = aeron_subscription_image_release(i.subscription, i.image)
        if retval < 0
            throwerror()
        end
    end
    i.released = true
    i.image = C_NULL
end

function Base.show(io::IO, ::MIME"text/plain", i::Image)
    println(io, "Image")
    println(io, "  source identity: $(source_identity(i))")
    println(io, "  correlation ID: $(correlation_id(i))")
    println(io, "  join position: $(join_position(i))")
    println(io, "  position bits to shift: $(position_bits_to_shift(i))")
    println(io, "  term buffer length: $(term_buffer_length(i))")
    println(io, "  MTU length: $(mtu_length(i))")
    println(io, "  session ID: $(session_id(i))")
    println(io, "  initial term ID: $(initial_term_id(i))")
    println(io, "  subscriber position ID: $(subscriber_position_id(i))")
    println(io, "  open: $(isopen(i))")
    println(io, "  position: $(position(i))")
    println(io, "  is end of stream: $(is_end_of_stream(i))")
    println(io, "  end of stream position: $(end_of_stream_position(i))")
end
