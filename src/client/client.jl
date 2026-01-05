"""
    struct Client

Represents a client for the Aeron messaging system.

# Fields
- `client::Ptr{aeron_t}`: Pointer to the underlying Aeron client.
- `context::Context`: The context associated with the client.
"""
struct Client
    client::Ptr{aeron_t}
    context::Context

    """
    Client(context::Context) -> Client

    Create a new `Client`.
    """
    function Client(context::Context)
        c = Ref{Ptr{aeron_t}}(C_NULL)
        if aeron_init(c, pointer(context)) < 0
            throwerror()
        end

        if aeron_start(c[]) < 0
            throw(ErrorException("aeron_start failed"))
        end

        new(c[], context)
    end
end

function Client(f::Function, context)
    c = Client(context)
    try
        f(c)
    finally
        close(c)
    end
end

function Client(f::Function)
    Context() do context
        c = Client(context)
        try
            f(c)
        finally
            close(c)
        end
    end
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
end

"""
    isopen(c::Client) -> Bool

Check if the given `Client` is open.

# Arguments
- `c::Client`: The client to check.

# Returns
- `Bool`: `true` if the client is open, `false` otherwise.
"""
Base.isopen(c::Client) = !aeron_is_closed(c.client)

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
    pointer(c::Client) -> Ptr{aeron_t}

Get the underlying Aeron client pointer.

# Arguments
- `c::Client`: The client instance.

# Returns
- `Ptr{aeron_t}`: Pointer to the Aeron client.
"""
pointer(c::Client) = c.client

Base.cconvert(::Type{Ptr{aeron_t}}, c::Client) = c
Base.unsafe_convert(::Type{Ptr{aeron_t}}, c::Client) = c.client

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
    do_work(c::Client) -> Int32

Perform one client conductor work cycle for the given `Client`.

Use this when `use_conductor_agent_invoker!(ctx, true)` is enabled.
# Arguments
- `c::Client`: The client instance.

# Returns
- `Int32`: The result of the work.
"""
do_work(c::Client) = Int(aeron_main_do_work(c.client))

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
end
