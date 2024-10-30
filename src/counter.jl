mutable struct Counter
    counter::Ptr{aeron_counter_t}
    constants::aeron_counter_constants_t
    const allocated::Bool
    function Counter(counter::Ptr{aeron_counter_t}, allocated::Bool=false)
        constants = Ref{aeron_counter_constants_t}()
        if aeron_counter_constants(counter, constants) < 0
            throwerror()
        end
        finalizer(close, new(counter, constants[], allocated))
    end
end

struct AsyncAddCounter
    async::Ptr{aeron_async_add_counter_t}
end

function async_add_counter(c::Client, type_id, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString)
    async = Ref{Ptr{aeron_async_add_counter_t}}(C_NULL)

    if key_buffer === nothing
        if aeron_async_add_counter(async, c.client, type_id,
            C_NULL, 0, label, length(label)) < 0
            throwerror()
        end
    else
        if aeron_async_add_counter(async, c.client, type_id,
            key_buffer_ptr, key_buffer_len, label, length(label)) < 0
            throwerror()
        end
    end
    return AsyncAddCounter(async[])
end

function poll(a::AsyncAddCounter)
    counter = Ref{Ptr{aeron_counter_t}}(C_NULL)
    if aeron_async_add_counter_poll(counter, a.async) < 0
        throwerror()
    end
    if counter[] == C_NULL
        return nothing
    end
    return Counter(counter[], true)
end

function add_counter(c::Client, type_id, key_buffer::Union{Nothing,AbstractVector{UInt8}}, label::AbstractString)
    async = async_add_counter(c, type_id, key_buffer, label)
    while true
        counter = poll(async)
        if counter !== nothing
            return counter
        end
        yield()
    end
end

function Base.close(c::Counter)
    if c.allocated == true
        if aeron_counter_close(c.counter, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
    c.counter = C_NULL
end

registration_id(c::Counter) = c.constants.registration_id
counter_id(c::Counter) = c.constants.counter_id
Base.isopen(c::Counter) = !aeron_counter_is_closed(c.counter)

function Base.show(io::IO, mime::MIME"text/plain", c::Counter)
    println(io, "Counter")
    println(io, "  registration id: ", registration_id(c))
    println(io, "  counter id: ", counter_id(c))
end
