mutable struct Client
    context::Context
    client::Ptr{aeron_t}
    available_image_handler::Function
    unavailable_image_handler::Function
    function Client(context::Context)
        c = Ref{Ptr{aeron_t}}(C_NULL)
        if aeron_init(c, context_ptr(context)) < 0
            throwerror()
        end

        if aeron_start(c[]) < 0
            throw(ErrorException("aeron_start failed"))
        end

        finalizer(close, new(context, c[], default_available_image_handler, default_unavailable_image_handler))
    end
end

function Client()
    return Client(Context())
end

connect(context::Context) = Client(context)

function Base.close(c::Client)
    ccall(:jl_safe_printf, Cvoid, (Cstring, Cstring), "Finalizing %s.\n", repr(c))
    if aeron_close(c.client) < 0
        error("aeron_close failed")
    end
    c.client = C_NULL
end

function Base.isopen(c::Client)
    if c.client == C_NULL
        throw(ErrorException("aeron client is NULL"))
    end

    !aeron_is_closed(c.client)
end

clientid(c::Client) = aeron_client_id(c.client)
client_ptr(c::Client) = c.client
context(c::Client) = c.context
next_correlation_id(c::Client) = aeron_next_correlation_id(c.client)
version() = unsafe_string(aeron_version_full())

function available_image_handler!(callback::Function, c::Client)
    c.available_image_handler = callback
end

function unavailable_image_handler!(callback::Function, c::Client)
    c.on_unavailable_image = callback
end

function default_available_image_handler(c::Client, image)
    @info "Available image: session_id=$(session_id(image)) mtu_length=$(mtu_length(image)) term_length=$(term_buffer_length(image)) from $(source_identity(image))"
end

function default_unavailable_image_handler(c::Client, image)
    @info "Unavailable image: session_id=$(session_id(image))"
end