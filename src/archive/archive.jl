const ERROR_BUFFER_LENGTH = 256

struct Archive
    archive::Ptr{aeron_archive_t}
    client::Aeron.Client
    control_response_subscription::Aeron.Subscription
    error_message_buffer::Vector{UInt8}

    function Archive(archive::Ptr{aeron_archive_t}, context::Context)
        context.context = aeron_archive_get_and_own_archive_context(archive)

        new(archive,
            client(context),
            Aeron.Subscription(aeron_archive_get_control_response_subscription(archive), client(context), false),
            zeros(UInt8, ERROR_BUFFER_LENGTH))
    end
end

function Base.close(a::Archive)
    aeron_archive_close(a.archive)
end

"""
    show(io, ::MIME"text/plain", c)

Display the `Context` object in a human-readable format.

# Arguments
- `io`: The IO stream to write to.
- `::MIME"text/plain"`: The MIME type.
- `c`: The `Context` object.
"""
function Base.show(io::IO, ::MIME"text/plain", a::Archive)
    println(io, "Archive")
    println(io, "  archive id: ", archive_id(a))
    println(io, "  control session id: ", control_session_id(a))
end

struct RecordingDescriptor
    control_session_id::Int64
    correlation_id::Int64
    recording_id::Int64
    start_timestamp::Int64
    stop_timestamp::Int64
    start_position::Int64
    stop_position::Int64
    initial_term_id::Int32
    segment_file_length::Int32
    term_buffer_length::Int32
    mtu_length::Int32
    session_id::Int32
    stream_id::Int32
    stripped_channel::String
    original_channel::String
    source_identity::String

    function RecordingDescriptor(desc_p::Ptr{aeron_archive_recording_descriptor_t})
        desc = unsafe_load(desc_p)
        new(desc.control_session_id,
            desc.correlation_id,
            desc.recording_id,
            desc.start_timestamp,
            desc.stop_timestamp,
            desc.start_position,
            desc.stop_position,
            desc.initial_term_id,
            desc.segment_file_length,
            desc.term_buffer_length,
            desc.mtu_length,
            desc.session_id,
            desc.stream_id,
            unsafe_string(desc.stripped_channel),
            unsafe_string(desc.original_channel),
            unsafe_string(desc.source_identity)
        )
    end
end

function Base.show(io::IO, ::MIME"text/plain", desc::RecordingDescriptor)
    println(io, "RecordingDescriptor")
    println(io, "  control session id: ", desc.control_session_id)
    println(io, "  correlation id: ", desc.correlation_id)
    println(io, "  recording id: ", desc.recording_id)
    println(io, "  start timestamp: ", desc.start_timestamp)
    println(io, "  stop timestamp: ", desc.stop_timestamp)
    println(io, "  start position: ", desc.start_position)
    println(io, "  stop position: ", desc.stop_position)
    println(io, "  initial term id: ", desc.initial_term_id)
    println(io, "  segment file length: ", desc.segment_file_length)
    println(io, "  term buffer length: ", desc.term_buffer_length)
    println(io, "  mtu length: ", desc.mtu_length)
    println(io, "  session id: ", desc.session_id)
    println(io, "  stream id: ", desc.stream_id)
    println(io, "  stripped channel: ", desc.stripped_channel)
    println(io, "  original channel: ", desc.original_channel)
    println(io, "  source identity: ", desc.source_identity)
end

struct RecordingSubscriptionDescriptor
    control_session_id::Int64
    correlation_id::Int64
    subscription_id::Int64
    stream_id::Int32
    stripped_channel::String

    function RecordingSubscriptionDescriptor(desc_p::Ptr{aeron_archive_recording_subscription_descriptor_t})
        desc = unsafe_load(desc_p)
        new(desc.control_session_id,
            desc.correlation_id,
            desc.subscription_id,
            desc.stream_id,
            unsafe_string(desc.stripped_channel)
        )
    end
end

function Base.show(io::IO, ::MIME"text/plain", desc::RecordingSubscriptionDescriptor)
    println(io, "RecordingSubscriptionDescriptor")
    println(io, "  control session id: ", desc.control_session_id)
    println(io, "  correlation id: ", desc.correlation_id)
    println(io, "  subscription id: ", desc.subscription_id)
    println(io, "  stream id: ", desc.stream_id)
    println(io, "  stripped channel: ", desc.stripped_channel)
end

struct RecordingSignalDescriptor
    control_session_id::Int64
    recording_id::Int64
    subscription_id::Int64
    position::Int64
    recording_signal_code::Int32

    function RecordingSignalDescriptor(desc_p::Ptr{aeron_archive_recording_signal_t})
        desc = unsafe_load(desc_p)
        new(desc.control_session_id,
            desc.recording_id,
            desc.subscription_id,
            desc.position,
            desc.recording_signal_code
        )
    end
end

function Base.show(io::IO, ::MIME"text/plain", desc::RecordingSignalDescriptor)
    println(io, "RecordingSignalDescriptor")
    println(io, "  control session id: ", desc.control_session_id)
    println(io, "  recording id: ", desc.recording_id)
    println(io, "  subscription id: ", desc.subscription_id)
    println(io, "  position: ", desc.position)
    println(io, "  recording signal code: ", desc.recording_signal_code)
end

@enumx RecordingSignal::Int32 begin
    START = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_START)
    STOP = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_STOP)
    EXTEND = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_EXTEND)
    REPLICATE = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_REPLICATE)
    MERGE = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_MERGE)
    SYNC = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_SYNC)
    DELETE = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_DELETE)
    REPLICATE_END = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_REPLICATE_END)
    NULL_VALUE = Integer(AERON_ARCHIVE_CLIENT_RECORDING_SIGNAL_NULL_VALUE)
end

function Base.convert(::Type{aeron_archive_recording_signal_t}, signal::RecordingSignal.T)
    aeron_archive_recording_signal_t(Integer(signal))
end

function Base.convert(::Type{RecordingSignal.T}, signal::aeron_archive_recording_signal_t)
    RecordingSignal.T(signal)
end

@enumx SourceLocation::UInt32 begin
    LOCAL = Integer(AERON_ARCHIVE_SOURCE_LOCATION_LOCAL)
    REMOTE = Integer(AERON_ARCHIVE_SOURCE_LOCATION_REMOTE)
end

function Base.convert(::Type{aeron_archive_source_location_t}, source_location::SourceLocation.T)
    aeron_archive_source_location_t(Integer(source_location))
end

function Base.convert(::Type{SourceLocation.T}, source_location::aeron_archive_source_location_t)
    SourceLocation.T(source_location)
end

Base.@kwdef struct ReplayParams
    bounding_limit_counter_id::Int32 = AERON_NULL_VALUE
    file_io_max_length::Int32 = AERON_NULL_VALUE
    position::Int64 = AERON_NULL_VALUE
    length::Int64 = AERON_NULL_VALUE
    replay_token::Int64 = AERON_NULL_VALUE
    subscription_registration_id::Int64 = AERON_NULL_VALUE
end

function Base.convert(::Type{aeron_archive_replay_params_t}, params::ReplayParams)
    aeron_archive_replay_params_t(
        params.bounding_limit_counter_id,
        params.file_io_max_length,
        params.position,
        params.length,
        params.replay_token,
        params.subscription_registration_id
    )
end

function Base.cconvert(::Type{Ptr{aeron_archive_replay_params_t}}, params::ReplayParams)
    Ref(convert(aeron_archive_replay_params_t, params))
end

function Base.convert(::Type{ReplayParams}, params::aeron_archive_replay_params_t)
    ReplayParams(
        params.bounding_limit_counter_id,
        params.file_io_max_length,
        params.position,
        params.length,
        params.replay_token,
        params.subscription_registration_id
    )
end

Base.@kwdef struct ReplicationParams
    stop_position::Int64 = AERON_NULL_VALUE
    dst_recording_id::Int64 = AERON_NULL_VALUE
    live_destination::String = ""
    replication_channel::String = ""
    src_response_channel::String = ""
    channel_tag_id::Int64 = AERON_NULL_VALUE
    subscription_tag_id::Int64 = AERON_NULL_VALUE
    file_io_max_length::Int32 = AERON_NULL_VALUE
    replication_session_id::Int32 = AERON_NULL_VALUE
    encoded_credentials::Union{Nothing,String} = nothing
end

function Base.convert(::Type{aeron_archive_replication_params_t}, params::ReplicationParams)
    aeron_archive_replication_params_t(
        params.stop_position,
        params.dst_recording_id,
        Base.pointer(params.live_destination),
        Base.pointer(params.replication_channel),
        Base.pointer(params.src_response_channel),
        params.channel_tag_id,
        params.subscription_tag_id,
        params.file_io_max_length,
        params.replication_session_id,
        params.encoded_credentials === nothing ? C_NULL : params.encoded_credentials
    )
end

function Base.cconvert(::Type{Ptr{aeron_archive_replication_params_t}}, params::ReplicationParams)
    Ref(convert(aeron_archive_replication_params_t, params))
end

struct AsyncConnect
    async::Ptr{aeron_archive_async_connect_t}
    context::Context
end

function async_connect(c::Context)
    async = Ref{Ptr{aeron_archive_async_connect_t}}(C_NULL)

    if aeron_archive_async_connect(async, c.context) < 0
        Aeron.throwerror()
    end
    return AsyncConnect(async[], c)
end

"""
    poll(a::AsyncConnect) -> Union{Nothing, Archive}

Poll the status of an asynchronous connect request.

# Arguments
- `a::AsyncConnect`: The asynchronous connect object.

# Returns
- `Union{Nothing, Archive}`: The archive object if available, `nothing` otherwise.
"""
function poll(a::AsyncConnect)
    archive = Ref{Ptr{aeron_archive_t}}(C_NULL)
    if aeron_archive_async_connect_poll(archive, a.async) < 0
        Aeron.throwerror()
    end
    if archive[] == C_NULL
        return nothing
    end

    return Archive(archive[], a.context)
end

function connect(c::Context)
    archive = Ref{Ptr{aeron_archive_t}}(C_NULL)

    if aeron_archive_connect(archive, c.context) < 0
        Aeron.throwerror()
    end

    return Archive(archive[], c)
end

function connect(f::Function, c::Context)
    a = connect(c)
    try
        f(a)
    finally
        close(a)
    end
end

archive_id(a::Archive) = aeron_archive_get_archive_id(a.archive)
control_response_subscription(a::Archive) = a.control_response_subscription
control_session_id(a::Archive) = aeron_archive_control_session_id(a.archive)

function poll_for_recording_signals(a::Archive)
    count = Ref{Int32}(0)
    if aeron_archive_poll_for_recording_signals(count, a.archive) < 0
        Aeron.throwerror()
    end
    return count[]
end

function poll_for_error_response(a::Archive)
    if aeron_archive_poll_for_error_response(a.archive, Base.pointer(a.error_message_buffer), length(a.error_message_buffer)) < 0
        Aeron.throwerror()
    end
    return StringView(rstrip_nul(a.error_message_buffer))
end

function check_for_error_response(a::Archive)
    if aeron_archive_check_for_error_response(a.archive) < 0
        Aeron.throwerror()
    end
end

function add_recorded_publication(a::Archive, channel, stream_id)
    publication = Ref{Ptr{aeron_publication_t}}(C_NULL)
    if aeron_archive_add_recorded_publication(publication, a.archive, channel, stream_id) < 0
        Aeron.throwerror()
    end
    return Aeron.Publication(publication[], a.client)
end

function add_recorded_exclusive_publication(a::Archive, channel, stream_id)
    publication = Ref{Ptr{aeron_exclusive_publication_t}}(C_NULL)
    if aeron_archive_add_recorded_exclusive_publication(publication, a.archive, channel, stream_id) < 0
        Aeron.throwerror()
    end
    return Aeron.ExclusivePublication(publication[], a.client)
end

function start_recording(a::Archive, channel, stream_id, source_location::SourceLocation.T, auto_stop::Bool=false)
    subscription_id = Ref{Int64}(0)
    if aeron_archive_start_recording(subscription_id, a.archive, channel, stream_id, source_location, auto_stop) < 0
        Aeron.throwerror()
    end
    return subscription_id[]
end

function recording_position(a::Archive, recording_id)
    position = Ref{Int64}(0)
    if aeron_archive_get_recording_position(position, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return position[]
end

function start_position(a::Archive, recording_id)
    position = Ref{Int64}(0)
    if aeron_archive_get_start_position(position, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return position[]
end

function stop_position(a::Archive, recording_id)
    position = Ref{Int64}(0)
    if aeron_archive_get_stop_position(position, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return position[]
end

function max_recorded_position(a::Archive, recording_id)
    position = Ref{Int64}(0)
    if aeron_archive_max_recorded_position(position, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return position[]
end

function stop_recording(a::Archive, subscription_id)
    if aeron_archive_stop_recording_subscription(a.archive, subscription_id) < 0
        Aeron.throwerror()
    end
end

function try_stop_recording(a::Archive, subscription_id)
    stopped = Ref{Bool}(false)
    if aeron_archive_try_stop_recording_subscription(stopped, a.archive, subscription_id) < 0
        Aeron.throwerror()
    end
    return stopped[]
end

function stop_recording(a::Archive, channel::AbstractString, stream_id)
    if aeron_archive_stop_recording_channel_and_stream(a.archive, channel, stream_id) < 0
        Aeron.throwerror()
    end
end

function try_stop_recording(a::Archive, channel::AbstractString, stream_id)
    stopped = Ref{Bool}(false)
    if aeron_archive_try_stop_recording_channel_and_stream(stopped, a.archive, channel, stream_id) < 0
        Aeron.throwerror()
    end
    return stopped[]
end

function try_stop_recording_by_identity(a::Archive, recording_id)
    stopped = Ref{Bool}(false)
    if aeron_archive_try_stop_recording_by_identity(stopped, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return stopped[]
end

function stop_recording(a::Archive, p::Aeron.Publication)
    if aeron_archive_stop_recording_publication(a.archive, p.publication) < 0
        Aeron.throwerror()
    end
end

function stop_recording(a::Archive, p::Aeron.ExclusivePublication)
    if aeron_archive_stop_recording_exclusive_publication(a.archive, p.publication) < 0
        Aeron.throwerror()
    end
end

function find_last_matching_recording(a::Archive, min_recording_id, channel_fragment, stream_id, session_id)
    recording_id = Ref{Int64}(0)
    if aeron_archive_find_last_matching_recording(recording_id, a.archive, min_recording_id, channel_fragment, stream_id, session_id) < 0
        Aeron.throwerror()
    end
    return recording_id[]
end

function recording_descriptor_consumer_wrapper(descriptor, (callback, arg))
    callback(RecordingDescriptor(descriptor), arg)
    nothing
end

function recording_descriptor_consumer_cfunction(::T) where {T}
    @cfunction(recording_descriptor_consumer_wrapper, Cvoid, (Ptr{aeron_archive_recording_descriptor_t}, Ref{T}))
end

function list_recording(callback::Function, a::Archive, recording_id, clientd=nothing)
    cb = (callback, clientd)
    count = Ref{Int32}(0)
    GC.@preserve cb begin
        if aeron_archive_list_recording(count, a.archive, recording_id,
            recording_descriptor_consumer_cfunction(cb), Ref(cb)) < 0
            Aeron.throwerror()
        end
    end
    return count[]
end

function list_recordings(callback::Function, a::Archive, from_recording_id, record_count, clientd=nothing)
    cb = (callback, clientd)
    count = Ref{Int32}(0)
    GC.@preserve cb begin
        if aeron_archive_list_recordings(count, a.archive, from_recording_id, record_count,
            recording_descriptor_consumer_cfunction(cb), Ref(cb)) < 0
            Aeron.throwerror()
        end
    end
    return count[]
end

function list_recordings_for_uri(callback::Function, a::Archive, from_recording_id, record_count, channel_fragment, stream_id, clientd=nothing)
    cb = (callback, clientd)
    count = Ref{Int32}(0)
    GC.@preserve cb begin
        if aeron_archive_list_recordings_for_uri(count, a.archive, from_recording_id, record_count, channel_fragment, stream_id,
            recording_descriptor_consumer_cfunction(cb), Ref(cb)) < 0
            Aeron.throwerror()
        end
    end
    return count[]
end

function start_replay(a::Archive, recording_id, replay_channel, replay_stream_id; kwargs...)
    replay_session_id = Ref{Int64}(0)
    params = ReplayParams(; kwargs...)
    if aeron_archive_start_replay(replay_session_id, a.archive, recording_id, replay_channel, replay_stream_id, params) < 0
        Aeron.throwerror()
    end
    return replay_session_id[]
end

function replay(a::Archive, recording_id, replay_channel, replay_stream_id; kwargs...)
    subscription = Ref{Ptr{aeron_subscription_t}}(C_NULL)
    params = ReplayParams(; kwargs...)
    if aeron_archive_replay(subscription, a.archive, recording_id, replay_channel, replay_stream_id, params) < 0
        Aeron.throwerror()
    end
    return Aeron.Subscription(subscription[], a.client)
end

function truncate_recording(a::Archive, recording_id, position)
    if aeron_archive_truncate_recording(a.archive, recording_id, position) < 0
        Aeron.throwerror()
    end
end

function stop_replay(a::Archive, replay_session_id)
    if aeron_archive_stop_replay(a.archive, replay_session_id) < 0
        Aeron.throwerror()
    end
end

function stop_all_replays(a::Archive, recording_id)
    if aeron_archive_stop_all_replays(a.archive, recording_id) < 0
        Aeron.throwerror()
    end
end

function recording_subscription_descriptor_consumer_wrapper(descriptor, (callback, arg))
    callback(RecordingSubscriptionDescriptor(descriptor), arg)
    nothing
end

function recording_subscription_descriptor_consumer_cfunction(::T) where {T}
    @cfunction(recording_subscription_descriptor_consumer_wrapper, Cvoid, (Ptr{aeron_archive_recording_descriptor_t}, Ref{T}))
end

function list_recording_subscriptions(callback::Function,
    a::Archive, pseudo_index, subscription_count, channel_fragment, stream_id, apply_stream_id, clientd=nothing)
    cb = (callback, clientd)
    count = Ref{Int32}(0)
    GC.@preserve cb begin
        if aeron_archive_list_recording_subscriptions(count, a.archive, pseudo_index, subscription_count,
            channel_fragment, stream_id, apply_stream_id,
            recording_subscription_descriptor_consumer_cfunction(cb), Ref(cb)) < 0
            Aeron.throwerror()
        end
    end
    return count[]
end

function purge_recording(a::Archive, recording_id)
    count = Ref{Int64}(0)
    if aeron_archive_purge_recording(count, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return count[]
end

function extend_recording(a::Archive, recording_id, channel, stream_id, source_location::SourceLocation.T, auto_stop::Bool=false)
    subscription_id = Ref{Int64}(0)
    if aeron_archive_extend_recording(subscription_id, a.archive, recording_id, channel, stream_id, source_location, auto_stop) < 0
        Aeron.throwerror()
    end
    return subscription_id[]
end

function replicate(a::Archive, src_recording_id, src_control_channel, src_control_stream_id; kwargs...)
    replication_id = Ref{Int64}(0)
    params = ReplicationParams(; kwargs...)
    if aeron_archive_replicate(replication_id, a.archive, src_recording_id, src_control_channel, src_control_stream_id, params) < 0
        Aeron.throwerror()
    end
    return replication_id[]
end

function stop_replication(a::Archive, replication_id)
    if aeron_archive_stop_replication(a.archive, replication_id) < 0
        Aeron.throwerror()
    end
end

function try_stop_replication(a::Archive, replication_id)
    stopped = Ref{Bool}(false)
    if aeron_archive_try_stop_replication(stopped, a.archive, replication_id) < 0
        Aeron.throwerror()
    end
    return stopped[]
end

function detach_segments(a::Archive, recording_id, new_start_position)
    if aeron_archive_detach_segments(a.archive, recording_id, new_start_position) < 0
        Aeron.throwerror()
    end
end

function delete_detached_segments(a::Archive, recording_id)
    count = Ref{Int64}(0)
    if aeron_archive_delete_detached_segments(count, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return count[]
end

function purge_segments(a::Archive, recording_id, new_start_position)
    count = Ref{Int64}(0)
    if aeron_archive_purge_segments(count, a.archive, recording_id, new_start_position) < 0
        Aeron.throwerror()
    end
    return count[]
end

function attach_segments(a::Archive, recording_id)
    count = Ref{Int64}(0)
    if aeron_archive_attach_segments(count, a.archive, recording_id) < 0
        Aeron.throwerror()
    end
    return count[]
end

function migrate_segments(a::Archive, src_recording_id, dst_recording_id)
    count = Ref{Int64}(0)
    if aeron_archive_migrate_segments(count, a.archive, src_recording_id, dst_recording_id) < 0
        Aeron.throwerror()
    end
    return count[]
end

function segment_file_base_position(start_position, position, term_buffer_length, segment_file_length)
    aeron_archive_segment_file_base_position(start_position, position, term_buffer_length, segment_file_length)
end

function find_counter_by_recording_id(c::Aeron.CountersReader, recording_id)
    counter_id = aeron_archive_recording_pos_find_counter_id_by_recording_id(c.counters_reader, recording_id)
    if counter_id < 0
        return nothing
    end
    return counter_id
end

function find_counter_by_session_id(c::Aeron.CountersReader, session_id)
    counter_id = aeron_archive_recording_pos_find_counter_id_by_session_id(c.counters_reader, session_id)
    if counter_id < 0
        return nothing
    end
    return counter_id
end

function recording_id(c::Aeron.CountersReader, counter_id)
    recording_id = aeron_archive_recording_pos_get_recording_id(c.counters_reader, counter_id)
end

function source_identity(c::Aeron.CountersReader, counter_id)
    len = Ref{Csize_t}(0)
    buf = Vector{UInt8}(undef, 256)
    GC.@preserve buf begin
        if aeron_archive_recording_pos_get_source_identity(c.counters_reader, counter_id, Base.pointer(buf), len) < 0
            Aeron.throwerror()
        end
        return String(buf[1:len[]])
    end
end

function is_active(c::Aeron.CountersReader, counter_id, recording_id)
    active = Ref{Bool}(false)
    if aeron_archive_recording_pos_is_active(active, c.counters_reader, counter_id, recording_id) < 0
        Aeron.throwerror()
    end
    return active[]
end

Aeron.CountersReader(a::Archive) = Aeron.CountersReader(a.client)
