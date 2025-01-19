"""
Context()

Create a new `Context` object and initialize it with default values.
The default values are read from environment variables.

# Throws
- `ErrorException` if initialization fails.
"""
mutable struct Context
    context::Ptr{aeron_archive_context_t}
    credentials_supplier::CredentialsSupplier

    # Callback references to prevent garbage collection
    error_handler::Tuple{Function,Any}
    signal_consumer::Tuple{Function,Any}

    function Context()
        p = Ref{Ptr{aeron_archive_context_t}}(C_NULL)
        if aeron_archive_context_init(p) < 0
            Aeron.throwerror()
        end

        context = new(p[], CredentialsSupplier())
        credentials_supplier!(context, context.credentials_supplier)

        attach_callbacks_to_context(context)

        finalizer(context) do c
            aeron_archive_context_close(c.context)
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
function Context(aerondir::AbstractString)
    c = Context()
    aeron_dir!(c, aerondir)
    return c
end

"""
    Context(control_request_channel, control_response_channel)

Create a new `Context` object and set the control request and response channels.

# Arguments
- `control_request_channel`: The control request channel.
- `control_response_channel`: The control response channel.

# Returns
- A new `Context` object with the specified control request and response channels.
"""
function Context(control_request_channel::AbstractString, control_response_channel::AbstractString)
    c = Context()
    control_request_channel!(c, control_request_channel)
    control_response_channel!(c, control_response_channel)
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
    close(c::Context)

Close the context and release any resources associated with it.
"""
function Base.close(c::Context)
    aeron_archive_context_close(c.context)
end

function client!(c::Context, client::Aeron.Client)
    aeron_archive_context_set_aeron(c.context, pointer(client))
end

function client(c::Context)
    aeron_archive_context_get_aeron(c.context)
end

"""
    aeron_dir(c)

Get the directory used for the media driver for `Context`.

# Arguments
- `c`: The `Context` object.

# Returns
- The directory name of the `Context`.
"""
aeron_dir(c::Context) = unsafe_string(aeron_archive_context_get_aeron_directory_name(c.context))

"""
    aeron_dir!(c, dir)

Set the media driver directory for `Context`.

# Arguments
- `c`: The `Context` object.
- `dir`: The media driver directory.

# Throws
- `ErrorException` if `aeron_archive_context_set_aeron_directory_name` fails.
"""
function aeron_dir!(c::Context, dir::AbstractString)
    if aeron_archive_context_set_aeron_directory_name(c.context, dir) < 0
        Aeron.throwerror()
    end
end

function control_request_channel!(c::Context, channel::String)
    if aeron_archive_context_set_control_request_channel(c.context, channel) < 0
        Aeron.throwerror()
    end
end

function control_request_channel(c::Context)
    ptr = aeron_archive_context_get_control_request_channel(c.context)
    return ptr == C_NULL ? "" : unsafe_string(ptr)
end

function control_request_stream_id!(c::Context, stream_id)
    aeron_archive_context_set_control_request_stream_id(c.context, stream_id)
end

control_request_stream_id(c::Context) = aeron_archive_context_get_control_request_stream_id(c.context)

function control_response_channel!(c::Context, channel::String)
    if aeron_archive_context_set_control_response_channel(c.context, channel) < 0
        Aeron.throwerror()
    end
end

function control_response_channel(c::Context)
    ptr = aeron_archive_context_get_control_response_channel(c.context)
    return ptr == C_NULL ? "" : unsafe_string(ptr)
end

function control_response_stream_id!(c::Context, stream_id)
    aeron_archive_context_set_control_response_stream_id(c.context, stream_id)
end

control_response_stream_id(c::Context) = aeron_archive_context_get_control_response_stream_id(c.context)

function recording_events_channel!(c::Context, channel::String)
    if aeron_archive_context_set_recording_events_channel(c.context, channel) < 0
        Aeron.throwerror()
    end
end

function recording_events_channel(c::Context)
    ptr = aeron_archive_context_get_recording_events_channel(c.context)
    return ptr == C_NULL ? "" : unsafe_string(ptr)
end

function recording_events_stream_id!(c::Context, stream_id)
    aeron_archive_context_set_recording_events_stream_id(c.context, stream_id)
end

recording_events_stream_id(c::Context) = aeron_archive_context_get_recording_events_stream_id(c.context)

function message_timeout_ns!(c::Context, timeout_ns::Int64)
    aeron_archive_context_set_message_timeout_ns(c.context, timeout_ns)
end

message_timeout_ns(c::Context) = aeron_archive_context_get_message_timeout_ns(c.context)

function control_term_buffer_length!(c::Context, length)
    aeron_archive_context_set_control_term_buffer_length(c.context, length)
end

control_term_buffer_length(c::Context) = aeron_archive_context_get_control_term_buffer_length(c.context)

function control_mtu_length!(c::Context, length::Int32)
    aeron_archive_context_set_control_mtu_length(c.context, length)
end

control_mtu_length(c::Context) = aeron_archive_context_get_control_mtu_length(c.context)

function control_term_buffer_sparse!(c::Context, sparse::Bool)
    aeron_archive_context_set_control_term_buffer_sparse(c.context, sparse)
end

control_term_buffer_sparse(c::Context) = aeron_archive_context_get_control_term_buffer_sparse(c.context)

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
    println(io, "  control request channel: ", control_request_channel(c))
    println(io, "  control request stream id: ", control_request_stream_id(c))
    println(io, "  control response channel: ", control_response_channel(c))
    println(io, "  control response stream id: ", control_response_stream_id(c))
    println(io, "  recording events channel: ", recording_events_channel(c))
    println(io, "  recording events stream id: ", recording_events_stream_id(c))
    println(io, "  message timeout ns: ", message_timeout_ns(c))
    println(io, "  control term buffer length: ", control_term_buffer_length(c))
    println(io, "  control mtu length: ", control_mtu_length(c))
    println(io, "  control term buffer sparse: ", control_term_buffer_sparse(c))
end

###############

function credentials_supplier!(c::Context, supplier::CredentialsSupplier)
    if aeron_archive_context_set_credentials_supplier(c.context,
        credentials_encoded_credentials_supplier_cfunction(supplier),
        credentials_encoded_challenge_supplier_cfunction(supplier),
        C_NULL,
        Ref(supplier)) < 0
        Aeron.throwerror()
    end
end

function recording_signal_consumer_wrapper(descriptor, (callback, arg))
    callback(RecordingSignalDescriptor(descriptor), arg)
    nothing
end

function recording_signal_consumer_cfunction(::T) where {T}
    @cfunction(recording_signal_consumer_wrapper, Cvoid, (Ptr{aeron_archive_recording_signal_t}, Ref{T}))
end

function recording_signal_consumer!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.signal_consumer = cb
    if aeron_archive_context_set_recording_signal_consumer(c.context, recording_signal_consumer_cfunction(cb), Ref(cb)) < 0
        Aeron.throwerror()
    end
end

function error_handler_wrapper((callback, clientd), errcode, message)
    callback(clientd, errcode, unsafe_string(message))
end

function error_handler_cfunction(::T) where {T}
    @cfunction(error_handler_wrapper, Cvoid, (Ref{T}, Cint, Cstring))
end

"""
    error_handler!(callback, c, clientd)

Set the error handler callback function.

# Arguments
- `callback`: The callback function to set.
- `c`: The `Context` object.
- `clientd=nothing`: The client data to pass to the callback function.

# Throws
- `ErrorException` if `aeron_archive_context_set_error_handler` fails.
"""
function error_handler!(callback::Function, c::Context, clientd=nothing)
    cb = (callback, clientd)
    c.error_handler = cb
    if aeron_archive_context_set_error_handler(c.context, error_handler_cfunction(cb), Ref(cb)) < 0
        Aeron.throwerror()
    end
end

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

    recording_signal_consumer!(c) do descriptor, _
    end
end
