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

position(h::Header) = aeron_header_position(h.header)
position_bits_to_shift(h::Header) = aeron_header_position_bits_to_shift(h.header)
next_term_offset(h::Header) = aeron_header_next_term_offset(h.header)
initial_term_id(h::Header) = h.values.initial_term_id
frame_length(h::Header) = h.values.frame.frame_length
version(h::Header) = h.values.frame.version
flags(h::Header) = h.values.frame.flags
type(h::Header) = h.values.frame.type
term_offset(h::Header) = h.values.frame.term_offset
session_id(h::Header) = h.values.frame.session_id
stream_id(h::Header) = h.values.frame.stream_id
term_id(h::Header) = h.values.frame.term_id

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
