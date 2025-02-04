"""
Context()

Create a new `Context` object and initialize it with default values.

# Throws
- `ErrorException` if initialization fails.
"""
mutable struct Context
    context::Ptr{aeron_context_t}

    # Callback references to prevent garbage collection
    error_handler::Tuple{Function,Any}
    on_new_publication::Tuple{Function,Any}
    on_new_exclusive_publication::Tuple{Function,Any}
    on_new_subscription::Tuple{Function,Any}
    on_available_counter::Tuple{Function,Any}
    on_unavailable_counter::Tuple{Function,Any}
    on_close_client::Tuple{Function,Any}

    function Context()
        p = Ref{Ptr{aeron_context_t}}(C_NULL)
        if aeron_context_init(p) < 0
            throwerror()
        end

        context = new(p[])
        attach_callbacks_to_context(context)

        finalizer(context) do c
            aeron_context_close(c.context)
        end
    end
end

"""
    Context(dirname)

Create a new `Context` object and set the media driver directory.

# Arguments
- `dirname`: The media driver directory name to set.

# Returns
- A new `Context` object with the specified media driver directory.
"""
function Context(dirname::AbstractString)
    c = Context()
    aeron_dir!(c, dirname)
    return c
end

"""
    pointer(c)

Get the pointer to the underlying `aeron_context_t` struct.

# Arguments
- `c`: The `Context` object.

# Returns
- The pointer to the underlying `aeron_context_t` struct.
"""
pointer(c::Context) = c.context

"""
    close(c)

Close and delete the `Context` object.

# Arguments
- `c`: The `Context` object to close.

# Throws
- `ErrorException` if `aeron_context_close` fails.
"""
function Base.close(c::Context)
    if aeron_context_close(c.context) < 0
        throw(ErrorException("aeron_context_close failed"))
    end
    c.context = C_NULL
end

"""
    aeron_dir(c)

Get the directory used for the media driver for `Context`.

# Arguments
- `c`: The `Context` object.

# Returns
- The directory name of the `Context`.
"""
aeron_dir(c::Context) = unsafe_string(aeron_context_get_dir(c.context))

"""
    aeron_dir!(c, dir)

Set the media driver directory for `Context`.

# Arguments
- `c`: The `Context` object.
- `dir`: The media driver directory.

# Throws
- `ErrorException` if `aeron_context_set_dir` fails.
"""
function aeron_dir!(c::Context, dir::AbstractString)
    if aeron_context_set_dir(c.context, dir) < 0
        throwerror()
    end
end

"""
    driver_timeout_ms(c)

Get the driver timeout in milliseconds.

# Arguments
- `c`: The `Context` object.

# Returns
- The driver timeout in milliseconds.
"""
driver_timeout_ms(c::Context) = aeron_context_get_driver_timeout_ms(c.context)

"""
    driver_timeout_ms!(c, timeout)

Set the driver timeout in milliseconds.

# Arguments
- `c`: The `Context` object.
- `timeout`: The driver timeout to set in milliseconds.

# Throws
- `ErrorException` if `aeron_context_set_driver_timeout_ms` fails.
"""
function driver_timeout_ms!(c::Context, timeout)
    if aeron_context_set_driver_timeout_ms(c.context, timeout) < 0
        throwerror()
    end
end

"""
    keepalive_internal_ns(c)

Get the keepalive interval in nanoseconds.

# Arguments
- `c`: The `Context` object.

# Returns
- The keepalive interval in nanoseconds.
"""
keepalive_internal_ns(c::Context) = aeron_context_get_keepalive_interval_ns(c.context)

"""
    keepalive_internal_ns!(c, interval)

Set the keepalive interval in nanoseconds.

# Arguments
- `c`: The `Context` object.
- `interval`: The keepalive interval to set in nanoseconds.

# Throws
- `ErrorException` if `aeron_context_set_keepalive_interval_ns` fails.
"""
function keepalive_internal_ns!(c::Context, interval)
    if aeron_context_set_keepalive_interval_ns(c.context, interval) < 0
        throwerror()
    end
end

"""
    resource_linger_duration_ns(c)

Get the resource linger duration in nanoseconds.

# Arguments
- `c`: The `Context` object.

# Returns
- The resource linger duration in nanoseconds.
"""
resource_linger_duration_ns(c::Context) = aeron_context_get_resource_linger_duration_ns(c.context)

"""
    resource_linger_duration_ns!(c, duration)

Set the resource linger duration in nanoseconds.

# Arguments
- `c`: The `Context` object.
- `duration`: The resource linger duration to set in nanoseconds.

# Throws
- `ErrorException` if `aeron_context_set_resource_linger_duration_ns` fails.
"""
function resource_linger_duration_ns!(c::Context, duration)
    if aeron_context_set_resource_linger_duration_ns(c.context, duration) < 0
        throwerror()
    end
end

"""
    idle_sleep_duration_ns(c)

Get the idle sleep duration in nanoseconds.

# Arguments
- `c`: The `Context` object.

# Returns
- The idle sleep duration in nanoseconds.
"""
idle_sleep_duration_ns(c::Context) = aeron_context_get_idle_sleep_duration_ns(c.context)

"""
    idle_sleep_duration_ns!(c, duration)

Set the idle sleep duration in nanoseconds.

# Arguments
- `c`: The `Context` object.
- `duration`: The idle sleep duration to set in nanoseconds.

# Throws
- `ErrorException` if `aeron_context_set_idle_sleep_duration_ns` fails.
"""
function idle_sleep_duration_ns!(c::Context, duration)
    if aeron_context_set_idle_sleep_duration_ns(c.context, duration) < 0
        throwerror()
    end
end

"""
    pre_touch_mapped_memory(c)

Get the pre-touch mapped memory setting.

# Arguments
- `c`: The `Context` object.

# Returns
- The pre-touch mapped memory setting.
"""
pre_touch_mapped_memory(c::Context) = aeron_context_get_pre_touch_mapped_memory(c.context)

"""
    pre_touch_mapped_memory!(c, pre_touch)

Set the pre-touch mapped memory setting.

# Arguments
- `c`: The `Context` object.
- `pre_touch`: The pre-touch mapped memory setting to set.

# Throws
- `ErrorException` if `aeron_context_set_pre_touch_mapped_memory` fails.
"""
function pre_touch_mapped_memory!(c::Context, pre_touch::Bool)
    if aeron_context_set_pre_touch_mapped_memory(c.context, pre_touch) < 0
        throwerror()
    end
end

"""
    client_name(c)

Get the client name.

# Arguments
- `c`: The `Context` object.

# Returns
- The client name.
"""
client_name(c::Context) = unsafe_string(aeron_context_get_client_name(c.context))

"""
    show(io, ::MIME"text/plain", c)

Display the `Context` object in a human-readable format.

# Arguments
- `io`: The IO stream to write to.
- `::MIME"text/plain"`: The MIME type.
- `c`: The `Context` object.
"""
function Base.show(io::IO, ::MIME"text/plain", c::Context)
    println(io, "Context")
    println(io, "  aeron_dir: ", aeron_dir(c))
    println(io, "  driver timeout (ms): ", driver_timeout_ms(c))
    println(io, "  keepalive internal (ns): ", keepalive_internal_ns(c))
    println(io, "  resource linger duration (ns): ", resource_linger_duration_ns(c))
    println(io, "  idle sleep duration (ns): ", idle_sleep_duration_ns(c))
    println(io, "  pre-touch mapped memory: ", pre_touch_mapped_memory(c))
    println(io, "  client name: ", client_name(c))
end

function error_handler_wrapper((callback, clientd), errcode, message)
    callback(clientd, errcode, unsafe_string(message))
end

function error_handler_cfunction(::T) where {T}
    @cfunction(error_handler_wrapper, Cvoid, (Ref{T}, Cint, Cstring))
end

function new_publication_handler_wrapper((callback, clientd), async, channel, stream_id, session_id, correlation_id)
    callback(clientd, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function new_publication_handler_cfunction(::T) where {T}
    @cfunction(new_publication_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_async_add_publication_t}, Cstring, Int32, Int32, Int64))
end

function new_exclusive_publication_handler_wrapper((callback, clientd), async, channel, stream_id, session_id, correlation_id)
    callback(clientd, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function new_exclusive_publication_handler_cfunction(::T) where {T}
    @cfunction(new_exclusive_publication_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_async_add_publication_t}, Cstring, Int32, Int32, Int64))
end

function new_subscription_handler_wrapper((callback, clientd), async, channel, stream_id, session_id, correlation_id)
    callback(clientd, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function new_subscription_handler_cfunction(::T) where {T}
    @cfunction(new_subscription_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_async_add_subscription_t}, Cstring, Int32, Int32, Int64))
end

function available_counter_handler_wrapper((callback, clientd), counters_reader, registration_id, counter_id)
    callback(clientd, registration_id, counter_id)
end

function available_counter_handler_cfunction(::T) where {T}
    @cfunction(available_counter_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_counters_reader_t}, Int64, Int32))
end

function unavailable_counter_handler_wrapper((callback, clientd), counters_reader, registration_id, counter_id)
    callback(clientd, registration_id, counter_id)
end

function unavailable_counter_handler_cfunction(::T) where {T}
    @cfunction(unavailable_counter_handler_wrapper, Cvoid, (Ref{T}, Ptr{aeron_counters_reader_t}, Int64, Int32))
end

function close_client_handler_wrapper((callback, clientd))
    callback(clientd)
end

function close_client_handler_cfunction(::T) where {T}
    @cfunction(close_client_handler_wrapper, Cvoid, (Ref{T},))
end

###################

"""
    error_handler!(callback, c, clientd)

Set the error handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_error_handler` fails.
"""
function error_handler!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.error_handler = cb
    GC.@preserve cb begin
        if aeron_context_set_error_handler(c.context, error_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_new_publication!(callback, c, clientd)

Set the new publication handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_new_publication` fails.
"""
function on_new_publication!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_new_publication = cb
    GC.@preserve cb begin
        if aeron_context_set_on_new_publication(c.context, new_publication_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_new_exclusive_publication!(callback, c, clientd)

Set the new exclusive publication handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_new_exclusive_publication` fails.
"""
function on_new_exclusive_publication!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_new_exclusive_publication = cb
    GC.@preserve cb begin
        if aeron_context_set_on_new_exclusive_publication(c.context, new_exclusive_publication_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_new_subscription!(callback, c, clientd)

Set the new subscription handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_new_subscription` fails.
"""
function on_new_subscription!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_new_subscription = cb
    GC.@preserve cb begin
        if aeron_context_set_on_new_subscription(c.context, new_subscription_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_available_counter!(callback, c, clientd)

Set the available counter handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_available_counter` fails.
"""
function on_available_counter!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_available_counter = cb
    GC.@preserve cb begin
        if aeron_context_set_on_available_counter(c.context, available_counter_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_unavailable_counter!(callback, c, clientd)

Set the unavailable counter handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_unavailable_counter` fails.
"""
function on_unavailable_counter!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_unavailable_counter = cb
    GC.@preserve cb begin
        if aeron_context_set_on_unavailable_counter(c.context, unavailable_counter_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

"""
    on_close_client!(callback, c, clientd)

Set the close client handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_context_set_on_close_client` fails.
"""
function on_close_client!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.on_close_client = cb
    GC.@preserve cb begin
        if aeron_context_set_on_close_client(c.context, close_client_handler_cfunction(cb), Ref(cb)) < 0
            throwerror()
        end
    end
end

###################

"""
    attach_callbacks_to_context(c)

Attach default callback functions to the `Context` object.

# Arguments
- `c`: The `Context` object.
"""
function attach_callbacks_to_context(c::Context)
    error_handler!(c) do _, errcode, message
        @error "Error: code=$errcode message=$message"
    end
end
