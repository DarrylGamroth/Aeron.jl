"""
    struct CnC

Represents a connection to the Aeron CnC (Command-and-Control) file for monitoring.
"""
mutable struct CnC
    cnc::Ptr{aeron_cnc_t}
    constants::aeron_cnc_constants_t

    function CnC(base_path::AbstractString; timeout_ms::Int64=5000)
        cnc = Ref{Ptr{aeron_cnc_t}}(C_NULL)
        if aeron_cnc_init(cnc, base_path, timeout_ms) < 0
            throwerror()
        end
        constants = Ref{aeron_cnc_constants_t}()
        if aeron_cnc_constants(cnc[], constants) < 0
            aeron_cnc_close(cnc[])
            throwerror()
        end
        new(cnc[], constants[])
    end
end

CnC(; base_path::AbstractString=default_path(), timeout_ms::Int64=5000) = CnC(base_path; timeout_ms=timeout_ms)

Base.cconvert(::Type{Ptr{aeron_cnc_t}}, c::CnC) = c
Base.unsafe_convert(::Type{Ptr{aeron_cnc_t}}, c::CnC) = c.cnc

"""
    close(c::CnC)

Close the CnC mapping and release resources.
"""
function Base.close(c::CnC)
    if c.cnc != C_NULL
        aeron_cnc_close(c.cnc)
        c.cnc = C_NULL
    end
end

"""
    cnc_version(c::CnC) -> Int32

Get the CnC version from the mapped file.
"""
cnc_version(c::CnC) = c.constants.cnc_version

"""
    client_liveness_timeout(c::CnC) -> Int64

Get the client liveness timeout from the CnC file.
"""
client_liveness_timeout(c::CnC) = c.constants.client_liveness_timeout

"""
    start_timestamp(c::CnC) -> Int64

Get the Aeron driver start timestamp.
"""
start_timestamp(c::CnC) = c.constants.start_timestamp

"""
    pid(c::CnC) -> Int64

Get the Aeron driver process ID.
"""
pid(c::CnC) = c.constants.pid

"""
    file_page_size(c::CnC) -> Int32

Get the mapped file page size.
"""
file_page_size(c::CnC) = c.constants.file_page_size

"""
    cnc_filename(c::CnC) -> String

Get the filename for the mapped CnC file.
"""
cnc_filename(c::CnC) = unsafe_string(aeron_cnc_filename(c.cnc))

"""
    to_driver_heartbeat(c::CnC) -> Int64

Get the timestamp of the last driver heartbeat.
"""
to_driver_heartbeat(c::CnC) = aeron_cnc_to_driver_heartbeat(c.cnc)

"""
    counters_reader(c::CnC) -> CountersReader

Get a counters reader backed by the CnC mapping.
"""
counters_reader(c::CnC) = CountersReader(aeron_cnc_counters_reader(c.cnc))

function error_log_reader_wrapper(observation_count, first_observation_timestamp, last_observation_timestamp,
    error, error_length, callback_ref::Ref)
    callback, clientd = callback_ref[]
    msg = StringView(UnsafeArray(error, (Int64(error_length),)))
    callback(observation_count, first_observation_timestamp, last_observation_timestamp, msg, clientd)
    nothing
end

function error_log_reader_cfunction(::T) where {T}
    @cfunction(error_log_reader_wrapper, Cvoid,
        (Int32, Int64, Int64, Ptr{UInt8}, Csize_t, Ref{T}))
end

"""
    error_log_read(callback, c::CnC; since_timestamp=0, clientd=nothing) -> Int

Read the CnC error log since `since_timestamp` and invoke `callback` for each entry.

The callback signature is:
`(observation_count::Int32, first_ts::Int64, last_ts::Int64, error::StringView, clientd)`
"""
function error_log_read(callback::Function, c::CnC; since_timestamp::Int64=0, clientd=nothing)
    cb = (callback, clientd)
    GC.@preserve cb begin
        return Int(aeron_cnc_error_log_read(c.cnc, error_log_reader_cfunction(cb), Ref(cb), since_timestamp))
    end
end

function loss_report_entry_wrapper(callback_ref::Ref, observation_count, total_bytes_lost,
    first_observation_timestamp, last_observation_timestamp, session_id, stream_id,
    channel, channel_length, source, source_length)
    callback, clientd = callback_ref[]
    channel_view = StringView(UnsafeArray(channel, (Int64(channel_length),)))
    source_view = StringView(UnsafeArray(source, (Int64(source_length),)))
    callback(observation_count, total_bytes_lost, first_observation_timestamp, last_observation_timestamp,
        session_id, stream_id, channel_view, source_view, clientd)
    nothing
end

function loss_report_entry_cfunction(::T) where {T}
    @cfunction(loss_report_entry_wrapper, Cvoid,
        (Ref{T}, Int64, Int64, Int64, Int64, Int32, Int32, Ptr{UInt8}, Int32, Ptr{UInt8}, Int32))
end

"""
    loss_report_read(callback, c::CnC; clientd=nothing) -> Int

Read the CnC loss report and invoke `callback` for each entry.

The callback signature is:
`(observation_count::Int64, total_bytes_lost::Int64, first_ts::Int64, last_ts::Int64, session_id::Int32,
  stream_id::Int32, channel::StringView, source::StringView, clientd)`
"""
function loss_report_read(callback::Function, c::CnC; clientd=nothing)
    cb = (callback, clientd)
    GC.@preserve cb begin
        return aeron_cnc_loss_reporter_read(c.cnc, loss_report_entry_cfunction(cb), Ref(cb))
    end
end
