"""
    struct Counter

Represents an Aeron counter, which is used for tracking various metrics.

# Fields

- `counter::Ptr{aeron_counter_t}`: Pointer to the underlying Aeron counter structure.
- `constants::aeron_counter_constants_t`: Constants associated with the counter.
- `is_owned::Bool`: Indicates whether the counter is owned by this instance.

# Constructor

- `Counter(counter::Ptr{aeron_counter_t}, is_owned::Bool=false)`

Creates a new `Counter` instance with the given Aeron counter pointer and allocation status.
"""
struct Counter
    counter::Ptr{aeron_counter_t}
    constants::aeron_counter_constants_t
    client::Client
    is_owned::Bool
    function Counter(counter::Ptr{aeron_counter_t}, client::Client, is_owned::Bool=false)
        constants = Ref{aeron_counter_constants_t}()
        if aeron_counter_constants(counter, constants) < 0
            throwerror()
        end
        return new(counter, constants[], client, is_owned)
    end
end

"""
    struct AsyncAddCounter

Represents an asynchronous add counter operation.

# Fields

- `async::Ptr{aeron_async_add_counter_t}`: Pointer to the underlying Aeron asynchronous add counter structure.
"""
struct AsyncAddCounter
    async::Ptr{aeron_async_add_counter_t}
    client::Client
end

"""
    async_add_counter(c::Client, type_id::Int32, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString) -> AsyncAddCounter

Initiates an asynchronous add counter operation.

# Arguments

- `c::Client`: The Aeron client.
- `type_id::Int32`: The type ID of the counter.
- `key_buffer::Union{Nothing,AbstractVector{UInt8}}`: The key buffer for the counter.
- `label::AbstractString`: The label for the counter.

# Returns

- `AsyncAddCounter`: The asynchronous add counter operation.
"""
function async_add_counter(c::Client, type_id::Int32, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString)
    async = Ref{Ptr{aeron_async_add_counter_t}}(C_NULL)

    if key_buffer === nothing
        if aeron_async_add_counter(async, c.client, type_id,
            C_NULL, 0, label, length(label)) < 0
            throwerror()
        end
    else
        if aeron_async_add_counter(async, c.client, type_id,
            key_buffer, length(key_buffer), label, length(label)) < 0
            throwerror()
        end
    end
    return AsyncAddCounter(async[], client)
end

"""
    poll(a::AsyncAddCounter) -> Union{Nothing, Counter}

Polls the completion of the asynchronous add counter operation.

# Arguments

- `a::AsyncAddCounter`: The asynchronous add counter operation.

# Returns

- `Union{Nothing, Counter}`: The counter if the operation is complete, otherwise `nothing`.
"""
function poll(a::AsyncAddCounter)
    counter = Ref{Ptr{aeron_counter_t}}(C_NULL)
    if aeron_async_add_counter_poll(counter, a.async) < 0
        throwerror()
    end
    if counter[] == C_NULL
        return nothing
    end
    return Counter(counter[], a.client, true)
end

"""
    add_counter(c::Client, type_id::Int32, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString) -> Counter

Adds a counter synchronously.

# Arguments

- `c::Client`: The Aeron client.
- `type_id::Int32`: The type ID of the counter.
- `key_buffer::Union{Nothing,AbstractVector{UInt8}}`: The key buffer for the counter.
- `label::AbstractString`: The label for the counter.

# Returns

- `Counter`: The added counter.
"""
function add_counter(c::Client, type_id::Int32, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString)
    async = async_add_counter(c, type_id, key_buffer, label)
    while true
        counter = poll(async)
        if counter !== nothing
            return counter
        end
        yield()
    end
end

"""
    Base.close(c::Counter)

Closes the `Counter` `c`, releasing any allocated resources.

# Arguments

- `c::Counter`: The counter to close.
"""
function Base.close(c::Counter)
    if c.is_owned
        if aeron_counter_close(c.counter, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
end

"""
    registration_id(c::Counter) -> Int64

Returns the registration ID of the `Counter` `c`.

The registration ID is a unique identifier for the counter.
"""
registration_id(c::Counter) = c.constants.registration_id

"""
    counter_id(c::Counter) -> Int32

Returns the counter ID of the `Counter` `c`.

The counter ID is a unique identifier for the counter within the Aeron client.
"""
counter_id(c::Counter) = c.constants.counter_id

"""
    Base.isopen(c::Counter) -> Bool

Returns `true` if the `Counter` `c` is open, `false` otherwise.

A counter is considered open if it has not been closed.
"""
Base.isopen(c::Counter) = !aeron_counter_is_closed(c.counter)

"""
    Base.show(io::IO, mime::MIME"text/plain", c::Counter)

Displays the `Counter` `c` in a human-readable format.

# Arguments

- `io::IO`: The IO stream to write to.
- `mime::MIME"text/plain"`: The MIME type for plain text.
- `c::Counter`: The counter to display.
"""
function Base.show(io::IO, mime::MIME"text/plain", c::Counter)
    println(io, "Counter")
    println(io, "  registration id: ", registration_id(c))
    println(io, "  counter id: ", counter_id(c))
end
