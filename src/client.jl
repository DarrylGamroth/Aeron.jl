mutable struct Client
    context::Context
    client::Ptr{aeron_t}
    function Client(context::Context)
        c = Ref{Ptr{aeron_t}}(C_NULL)
        if aeron_init(c, context_ptr(context)) < 0
            throwerror()
        end

        if aeron_start(c[]) < 0
            throw(ErrorException("aeron_start failed"))
        end

        finalizer(close, new(context, c[]))
    end
end

function Client()
    return Client(Context())
end

connect(context::Context) = Client(context)

function Base.close(c::Client)
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

client_id(c::Client) = aeron_client_id(c.client)
client_ptr(c::Client) = c.client
context(c::Client) = c.context
next_correlation_id(c::Client) = aeron_next_correlation_id(c.client)
version() = unsafe_string(aeron_version_full())

function Base.show(io::IO, mime::MIME"text/plain", c::Client)
    println(io, "Client")
    println(io, "  version: ", version())
    println(io, "  client id: ", client_id(c))
    println(io, "  next correlation id: ", next_correlation_id(c))
    show(io, mime, context(c))
end
