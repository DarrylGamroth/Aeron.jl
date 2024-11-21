"""
    struct Header

Represents an Aeron header, which contains metadata for a message frame.

# Fields

- `header::Ptr{aeron_header_t}`: Pointer to the underlying Aeron header structure.
- `values::aeron_header_values_t`: Values associated with the header.

# Constructor

- `Header(header::Ptr{aeron_header_t})`: Creates a new `Header` instance with the given Aeron header pointer.
"""
struct Header
    header::Ptr{aeron_header_t}
    values::aeron_header_values_t
    function Header(header::Ptr{aeron_header_t})
        values = Ref{aeron_header_values_t}()
        if aeron_header_values(header, values) < 0
            throwerror()
        end
        new(header, values[])
    end
end

"""
    pointer(h::Header) -> Ptr{aeron_header_t}

Returns the pointer to the Aeron header for the `Header` `h`.
"""
pointer(h::Header) = h.header

"""
    position(h::Header) -> Int64

Returns the position of the `Header` `h`.

The position is the offset within the term buffer where the frame begins.
"""
position(h::Header) = aeron_header_position(h.header)

"""
    position_bits_to_shift(h::Header) -> Int32

Returns the number of bits to shift for the position of the `Header` `h`.

This value is used for calculating the position within the term buffer.
"""
position_bits_to_shift(h::Header) = aeron_header_position_bits_to_shift(h.header)

"""
    next_term_offset(h::Header) -> Int32

Returns the offset for the next term in the `Header` `h`.

This value is used to determine the start of the next term.
"""
next_term_offset(h::Header) = aeron_header_next_term_offset(h.header)

"""
    initial_term_id(h::Header) -> Int32

Returns the initial term ID of the `Header` `h`.

The initial term ID is the ID of the first term in the stream.
"""
initial_term_id(h::Header) = h.values.initial_term_id

"""
    frame_length(h::Header) -> Int32

Returns the frame length of the `Header` `h`.

The frame length is the size of the message frame.
"""
frame_length(h::Header) = h.values.frame.frame_length

"""
    version(h::Header) -> Int32

Returns the version of the `Header` `h`.

The version indicates the protocol version used.
"""
version(h::Header) = h.values.frame.version

"""
    flags(h::Header) -> UInt8

Returns the flags of the `Header` `h`.

The flags indicate the type of frame and other control information.
"""
flags(h::Header) = h.values.frame.flags

"""
    type(h::Header) -> UInt16

Returns the type of the `Header` `h`.

The type indicates the kind of frame (e.g., data, padding).
"""
type(h::Header) = h.values.frame.type

"""
    term_offset(h::Header) -> Int32

Returns the term offset of the `Header` `h`.

The term offset is the offset within the term where the frame begins.
"""
term_offset(h::Header) = h.values.frame.term_offset

"""
    session_id(h::Header) -> Int32

Returns the session ID of the `Header` `h`.

The session ID is a unique identifier for the session associated with the frame.
"""
session_id(h::Header) = h.values.frame.session_id

"""
    stream_id(h::Header) -> Int32

Returns the stream ID of the `Header` `h`.

The stream ID is a unique identifier for the stream within the channel.
"""
stream_id(h::Header) = h.values.frame.stream_id

"""
    term_id(h::Header) -> Int32

Returns the term ID of the `Header` `h`.

The term ID is the ID of the term in which the frame is located.
"""
term_id(h::Header) = h.values.frame.term_id

"""
    Base.show(io::IO, mime::MIME"text/plain", h::Header)

Displays the `Header` `h` in a human-readable format.

# Arguments

- `io::IO`: The IO stream to write to.
- `mime::MIME"text/plain"`: The MIME type for plain text.
- `h::Header`: The header to display.
"""
function Base.show(io::IO, mime::MIME"text/plain", h::Header)
    println(io, "Header")
    println(io, "  position: ", position(h))
    println(io, "  position bits to shift: ", position_bits_to_shift(h))
    println(io, "  next term offset: ", next_term_offset(h))
    println(io, "  initial term id: ", initial_term_id(h))
    println(io, "  frame length: ", frame_length(h))
    println(io, "  version: ", version(h))
    println(io, "  flags: ", flags(h))
    println(io, "  type: ", type(h))
    println(io, "  term offset: ", term_offset(h))
    println(io, "  session id: ", session_id(h))
    println(io, "  stream id: ", stream_id(h))
    println(io, "  term id: ", term_id(h))
end
