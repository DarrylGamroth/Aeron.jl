mutable struct Context
    context::Ptr{aeron_context_t}
    error_handler::Function
    new_publication_handler::Function
    new_exclusive_publication_handler::Function
    new_subscription_handler::Function
    available_counter_handler::Function
    unavailable_counter_handler::Function
    close_client_handler::Function
    available_image_handler::Function
    unavailable_image_handler::Function
    function Context()
        p = Ref{Ptr{aeron_context_t}}(C_NULL)
        if aeron_context_init(p) < 0
            throw(ErrorException("aeron_context_init failed"))
        end

        context = new(p[])
        attach_callbacks_to_context(context)

        finalizer(close, context)
    end
end

function Context(dirname::AbstractString)
    c = Context()
    aeron_dir!(c, dirname)
    return c
end

context_ptr(c::Context) = c.context

function Base.close(c::Context)
    if aeron_context_close(c.context) < 0
        throw(ErrorException("aeron_context_close failed"))
    end
    c.context = C_NULL
end

aeron_dir(c::Context) = unsafe_string(aeron_context_get_dir(c.context))
function aeron_dir!(c::Context, dir::AbstractString)
    if aeron_context_set_dir(c.context, dir) < 0
        throwerror()
    end
end

driver_timeout_ms(c::Context) = aeron_context_get_driver_timeout_ms(c.context)
function driver_timeout_ms!(c::Context, timeout)
    if aeron_context_set_driver_timeout_ms(c.context, timeout) < 0
        throwerror()
    end
end

keepalive_internal_ns(c::Context) = aeron_context_get_keepalive_interval_ns(c.context)
function keepalive_internal_ns!(c::Context, interval)
    if aeron_context_set_keepalive_interval_ns(c.context, interval) < 0
        throwerror()
    end
end

resource_linger_duration_ns(c::Context) = aeron_context_get_resource_linger_duration_ns(c.context)
function resource_linger_duration_ns!(c::Context, duration)
    if aeron_context_set_resource_linger_duration_ns(c.context, duration) < 0
        throwerror()
    end
end

idle_sleep_duration_ns(c::Context) = aeron_context_get_idle_sleep_duration_ns(c.context)
function idle_sleep_duration_ns!(c::Context, duration)
    if aeron_context_set_idle_sleep_duration_ns(c.context, duration) < 0
        throwerror()
    end
end

pre_touch_mapped_memory(c::Context) = aeron_context_get_pre_touch_mapped_memory(c.context)
function pre_touch_mapped_memory!(c::Context, pre_touch::Bool)
    if aeron_context_set_pre_touch_mapped_memory(c.context, pre_touch) < 0
        throwerror()
    end
end

client_name(c::Context) = unsafe_string(aeron_context_get_client_name(c.context))
function client_name!(c::Context, name::AbstractString)
    if aeron_context_set_client_name(c.context, name) < 0
        throwerror()
    end
end

function Base.show(io::IO, ::MIME"text/plain", c::Context)
    println(io, "Context")
    println(io, "  aerondir: ", aeron_dir(c))
    println(io, "  driver timeout (ms): ", driver_timeout_ms(c))
    println(io, "  keepalive internal (ns): ", keepalive_internal_ns(c))
    println(io, "  resource linger duration (ns): ", resource_linger_duration_ns(c))
    println(io, "  idle sleep duration (ns): ", idle_sleep_duration_ns(c))
    println(io, "  pre-touch mapped memory: ", pre_touch_mapped_memory(c))
    println(io, "  client name: ", client_name(c))
end

function error_handler_wrapper(c::Context, errcode::Cint, message::Cstring)
    c.error_handler(c, errcode, unsafe_string(message))
end

function new_publication_handler_wrapper(c::Context, ::Ptr{aeron_async_add_publication_t},
    channel::Cstring, stream_id::Int32, session_id::Int32, correlation_id::Int64)
    c.new_publication_handler(c, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function new_exclusive_publication_handler_wrapper(c::Context, ::Ptr{aeron_async_add_publication_t},
    channel::Cstring, stream_id::Int32, session_id::Int32, correlation_id::Int64)
    c.new_exclusive_publication_handler(c, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function new_subscription_handler_wrapper(c::Context, ::Ptr{aeron_async_add_subscription_t},
    channel::Cstring, stream_id::Int32, session_id::Int32, correlation_id::Int64)
    c.new_subscription_handler(c, unsafe_string(channel), stream_id, session_id, correlation_id)
end

function available_counter_handler_wrapper(c::Context, ::Ptr{aeron_counters_reader_t},
    registration_id::Int64, counter_id::Int32)
    c.available_counter_handler(c, registration_id, counter_id)
end

function unavailable_counter_handler_wrapper(c::Context, ::Ptr{aeron_counters_reader_t},
    registration_id::Int64, counter_id::Int32)
    c.unavailable_counter_handler(c, registration_id, counter_id)
end

function close_client_handler_wrapper(c::Context)
    c.close_client_handler(c)
end

###################

function error_handler!(callback::Function, c::Context)
    c.error_handler = callback
    handler = @cfunction(error_handler_wrapper, Cvoid, (Ref{Context}, Cint, Cstring))
    if aeron_context_set_error_handler(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function new_publication_handler!(callback::Function, c::Context)
    c.new_publication_handler = callback
    handler = @cfunction(new_publication_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_async_add_publication_t}, Cstring, Int32, Int32, Int64))
    if aeron_context_set_on_new_publication(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function new_exclusive_publication_handler!(callback::Function, c::Context)
    c.new_exclusive_publication_handler = callback
    handler = @cfunction(new_exclusive_publication_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_async_add_publication_t}, Cstring, Int32, Int32, Int64))
    if aeron_context_set_on_new_exclusive_publication(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function new_subscription_handler!(callback::Function, c::Context)
    c.new_subscription_handler = callback
    handler = @cfunction(new_subscription_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_async_add_subscription_t}, Cstring, Int32, Int32, Int64))
    if aeron_context_set_on_new_subscription(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function available_counter_handler!(callback::Function, c::Context)
    c.available_counter_handler = callback
    handler = @cfunction(available_counter_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_counters_reader_t}, Int64, Int32))
    if aeron_context_set_on_available_counter(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function unavailable_counter_handler!(callback::Function, c::Context)
    c.unavailable_counter_handler = callback
    handler = @cfunction(unavailable_counter_handler_wrapper, Cvoid, (Ref{Context}, Ptr{aeron_counters_reader_t}, Int64, Int32))
    if aeron_context_set_on_unavailable_counter(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function close_client_handler!(callback::Function, c::Context)
    c.close_client_handler = callback
    handler = @cfunction(close_client_handler_wrapper, Cvoid, (Ref{Context},))
    if aeron_context_set_on_close_client(c.context, handler, Ref(c)) < 0
        throwerror()
    end
end

function available_image_handler!(callback::Function, c::Context)
    c.available_image_handler = callback
end

function unavailable_image_handler!(callback::Function, c::Context)
    c.unavailable_image_handler = callback
end

###################

function attach_callbacks_to_context(c::Context)
    error_handler!(c) do c, errcode, message
        @error "Error: code=$errcode message=$message"
    end
    new_publication_handler!(c) do c, channel, stream_id, session_id, correlation_id
        @info "New publication: channel=$channel stream_id=$stream_id session_id=$session_id correlation_id=$correlation_id"
    end
    new_exclusive_publication_handler!(c) do c, channel, stream_id, session_id, correlation_id
        @info "New exclusive publication: channel=$channel stream_id=$stream_id session_id=$session_id correlation_id=$correlation_id"
    end
    new_subscription_handler!(c) do c, channel, stream_id, session_id, correlation_id
        @info "New subscription: channel=$channel stream_id=$stream_id session_id=$session_id correlation_id=$correlation_id"
    end
    available_counter_handler!(c) do c, registration_id, counter_id
        @info "Available counter: registration_id=$registration_id counter_id=$counter_id"
    end
    unavailable_counter_handler!(c) do c, registration_id, counter_id
        @info "Unavailable counter: registration_id=$registration_id counter_id=$counter_id"
    end
    close_client_handler!(c) do c
        @info "Client closed"
    end
    available_image_handler!(c) do c, image
        @info "Available image: session_id=$(session_id(image)) mtu_length=$(mtu_length(image)) term_length=$(term_buffer_length(image)) from $(source_identity(image))"
    end
    unavailable_image_handler!(c) do c, image
        @info "Unavailable image: session_id=$(session_id(image))"
    end
end
