function print_available_image(image)
    println("Available image: session_id=$(Aeron.session_id(image)) mtu_length=$(Aeron.mtu_length(image)) term_length=$(Aeron.term_buffer_length(image)) from $(Aeron.source_identity(image))")
end

function print_unavailable_image(image)
    println("Unavailable image: session_id=$(Aeron.session_id(image)) from $(Aeron.source_identity(image))")
end