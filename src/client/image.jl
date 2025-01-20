"""
    struct Image

Represents an Aeron image, which is a stream of messages from a publication.

# Fields

- `image::Ptr{aeron_image_t}`: Pointer to the underlying Aeron image structure.
- `constants::aeron_image_constants_t`: Constants associated with the image.

# Constructor

- `Image(image::Ptr{aeron_image_t})`: Creates a new `Image` instance with the given Aeron image pointer.
"""
struct Image
    image::Ptr{aeron_image_t}
    constants::aeron_image_constants_t
    function Image(image::Ptr{aeron_image_t})
        constants = Ref{aeron_image_constants_t}()
        if aeron_image_constants(image, constants) < 0
            throwerror()
        end
        new(image, constants[])
    end
end

"""
    source_identity(i::Image) -> String

Returns the source identity of the `Image` `i`.

The source identity is a string that identifies the source of the image.
"""
source_identity(i::Image) = unsafe_string(i.constants.source_identity)

"""
    correlation_id(i::Image) -> Int64

Returns the correlation ID of the `Image` `i`.

The correlation ID is a unique identifier for the image.
"""
correlation_id(i::Image) = i.constants.correlation_id

"""
    join_position(i::Image) -> Int64

Returns the join position of the `Image` `i`.

The join position is the position in the stream where the image was joined.
"""
join_position(i::Image) = i.constants.join_position

"""
    position_bits_to_shift(i::Image) -> Int32

Returns the number of bits to shift for the position of the `Image` `i`.

This value is used for calculating the position within the term buffer.
"""
position_bits_to_shift(i::Image) = i.constants.position_bits_to_shift

"""
    term_buffer_length(i::Image) -> Int32

Returns the length of the term buffer for the `Image` `i`.

The term buffer length is the size of the buffer used for storing messages.
"""
term_buffer_length(i::Image) = i.constants.term_buffer_length

"""
    mtu_length(i::Image) -> Int32

Returns the Maximum Transmission Unit (MTU) length for the `Image` `i`.

The MTU length is the maximum size of a message that can be transmitted.
"""
mtu_length(i::Image) = i.constants.mtu_length

"""
    session_id(i::Image) -> Int32

Returns the session ID of the `Image` `i`.

The session ID is a unique identifier for the session associated with the image.
"""
session_id(i::Image) = i.constants.session_id

"""
    initial_term_id(i::Image) -> Int32

Returns the initial term ID of the `Image` `i`.

The initial term ID is the ID of the first term in the stream.
"""
initial_term_id(i::Image) = i.constants.initial_term_id

"""
    subscriber_position_id(i::Image) -> Int32

Returns the subscriber position ID of the `Image` `i`.

The subscriber position ID is the ID of the position of the subscriber in the stream.
"""
subscriber_position_id(i::Image) = i.constants.subscriber_position_id

"""
    Base.isopen(i::Image) -> Bool

Returns `true` if the `Image` `i` is open, `false` otherwise.

An image is considered open if it has not been closed.
"""
Base.isopen(i::Image) = !aeron_image_is_closed(i.image)