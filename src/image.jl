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

source_identity(i::Image) = unsafe_string(i.constants.source_identity)
correlation_id(i::Image) = i.constants.correlation_id
join_position(i::Image) = i.constants.join_position
position_bits_to_shift(i::Image) = i.constants.position_bits_to_shift
term_buffer_length(i::Image) = i.constants.term_buffer_length
mtu_length(i::Image) = i.constants.mtu_length
session_id(i::Image) = i.constants.session_id
initial_term_id(i::Image) = i.constants.initial_term_id
subscriber_position_id(i::Image) = i.constants.subscriber_position_id

Base.isopen(i::Image) = !aeron_image_is_closed(i.image)