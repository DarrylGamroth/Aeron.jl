"""
    struct Header

Represents an Aeron header, which contains metadata for a message frame.

# Fields

- `header::Ptr{aeron_header_t}`: Pointer to the underlying Aeron header structure.
- `values::aeron_header_values_t`: Values associated with the header.

# Constructor

- `Header(header::Ptr{aeron_header_t})`: Creates a new `Header` instance with the given Aeron header pointer.
"""
const Header = Ptr{aeron_header_t}

"""
    position(h::Header) -> Int64

Returns the position of the `Header` `h`.

The position is the offset within the term buffer where the frame begins.
"""
position(h::Header) = aeron_header_position(h)

"""
    position_bits_to_shift(h::Header) -> Int32

Returns the number of bits to shift for the position of the `Header` `h`.

This value is used for calculating the position within the term buffer.
"""
position_bits_to_shift(h::Header) = aeron_header_position_bits_to_shift(h)

"""
    next_term_offset(h::Header) -> Int32

Returns the offset for the next term in the `Header` `h`.

This value is used to determine the start of the next term.
"""
next_term_offset(h::Header) = aeron_header_next_term_offset(h)

"""
    values(h::Header) -> aeron_header_values_t
Returns the values associated with the `Header` `h`.
This function retrieves the values that contain metadata about the frame, such as initial term ID,
    frame length, version, flags, type, term offset, session ID, stream ID, and term ID.
"""
function values(h::Header)
    values = Ref{aeron_header_values_t}()
    if aeron_header_values(h, values) < 0
        throwerror()
    end
    return values[]
end

"""
    Base.show(io::IO, mime::MIME"text/plain", h::Header)

Displays the `Header` `h` in a human-readable format.

# Arguments

- `io::IO`: The IO stream to write to.
- `mime::MIME"text/plain"`: The MIME type for plain text.
- `h::Header`: The header to display.
"""
function Base.show(io::IO, mime::MIME"text/plain", h::Header)
    values = values(h)
    println(io, "Header")
    println(io, "  position: ", position(h))
    println(io, "  position bits to shift: ", position_bits_to_shift(h))
    println(io, "  next term offset: ", next_term_offset(h))
    println(io, "  frame length: ", values.frame_length)
    println(io, "  version: ", values.version)
    println(io, "  flags: ", values.flags)
    println(io, "  type: ", values.type)
    println(io, "  term offset: ", values.term_offset)
    println(io, "  session id: ", values.session_id)
    println(io, "  stream id: ", values.stream_id)
    println(io, "  term id: ", values.term_id)
end
