"""
    mutable struct Client

Represents a client for the Aeron messaging system.

# Fields
- `context::Context`: The context associated with the client.
- `client::Ptr{aeron_t}`: Pointer to the underlying Aeron client.
"""
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

        finalizer(new(context, c[])) do c
            aeron_close(c.client)
        end
    end
end

"""
    Client()

Create a new `Client` with a default `Context`.
"""
function Client()
    return Client(Context())
end

"""
    close(c::Client)

Close the given `Client`.

# Arguments
- `c::Client`: The client to be closed.
"""
function Base.close(c::Client)
    if aeron_close(c.client) < 0
        error("aeron_close failed")
    end
    c.client = C_NULL
end

"""
    isopen(c::Client) -> Bool

Check if the given `Client` is open.

# Arguments
- `c::Client`: The client to check.

# Returns
- `Bool`: `true` if the client is open, `false` otherwise.
"""
function Base.isopen(c::Client)
    if c.client == C_NULL
        throw(ErrorException("aeron client is NULL"))
    end
    !aeron_is_closed(c.client)
end

"""
    client_id(c::Client) -> Int64

Get the client ID of the given `Client`.

# Arguments
- `c::Client`: The client instance.

# Returns
- `Int64`: The client ID.
"""
client_id(c::Client) = aeron_client_id(c.client)

"""
    client_ptr(c::Client) -> Ptr{aeron_t}

Get the underlying Aeron client pointer.

# Arguments
- `c::Client`: The client instance.

# Returns
- `Ptr{aeron_t}`: Pointer to the Aeron client.
"""
client_ptr(c::Client) = c.client

"""
    context(c::Client) -> Context

Get the context associated with the given `Client`.

# Arguments
- `c::Client`: The client instance.

# Returns
- `Context`: The client's context.
"""
context(c::Client) = c.context

"""
    next_correlation_id(c::Client) -> Int64

Get the next correlation ID for the given `Client`.

# Arguments
- `c::Client`: The client instance.

# Returns
- `Int64`: The next correlation ID.
"""
next_correlation_id(c::Client) = aeron_next_correlation_id(c.client)

"""
    show(io::IO, mime::MIME"text/plain", c::Client)

Display the `Client` in a human-readable form.

# Arguments
- `io::IO`: The IO stream.
- `mime::MIME"text/plain"`: The MIME type.
- `c::Client`: The client instance.
"""
function Base.show(io::IO, mime::MIME"text/plain", c::Client)
    println(io, "Client")
    println(io, "  client id: ", client_id(c))
    println(io, "  next correlation id: ", next_correlation_id(c))
    show(io, mime, context(c))
end