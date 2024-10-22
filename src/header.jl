struct Header
    header::Ptr{aeron_header_t}
end

position(h::Header) = aeron_header_position(h.header)
position_bits_to_shift(h::Header) = aeron_header_position_bits_to_shift(h.header)
next_term_offset(h::Header) = aeron_header_next_term_offset(h.header)
