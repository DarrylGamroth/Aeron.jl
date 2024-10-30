const PUBLICATION_NOT_CONNECTED = AERON_PUBLICATION_NOT_CONNECTED
const PUBLICATION_BACK_PRESSURED = AERON_PUBLICATION_BACK_PRESSURED
const PUBLICATION_ADMIN_ACTION = AERON_PUBLICATION_ADMIN_ACTION
const PUBLICATION_CLOSED = AERON_PUBLICATION_CLOSED
const PUBLICATION_MAX_POSITION_EXCEEDED = AERON_PUBLICATION_MAX_POSITION_EXCEEDED
const PUBLICATION_ERROR = AERON_PUBLICATION_ERROR

const IOVECS_NUM = 4

mutable struct Publication
    publication::Ptr{aeron_publication_t}
    const constants::aeron_publication_constants_t
    const iovecs::Vector{aeron_iovec_t}
    const allocated::Bool
    function Publication(publication::Ptr{aeron_publication_t}, allocated::Bool=false)
        constants = Ref{aeron_publication_constants_t}()
        if aeron_publication_constants(publication, constants) < 0
            throwerror()
        end
        finalizer(close, new(publication, constants[],
            sizehint!(aeron_iovec_t[], IOVECS_NUM; shrink=false), allocated))
    end
end

struct AsyncAddPublication
    async::Ptr{aeron_async_add_publication_t}
end

function async_add_publication(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_publication_t}}(C_NULL)
    if aeron_async_add_publication(async, c.client, uri, stream_id) < 0
        throwerror()
    end
    return AsyncAddPublication(async[])
end

function poll(a::AsyncAddPublication)
    publication = Ref{Ptr{aeron_publication_t}}(C_NULL)
    if aeron_async_add_publication_poll(publication, a.async) < 0
        throwerror()
    end
    if publication[] == C_NULL
        return nothing
    end
    return Publication(publication[], true)
end

function add_publication(c::Client, uri::AbstractString, stream_id)
    async = async_add_publication(c, uri, stream_id)
    while true
        publication = poll(async)
        if publication !== nothing
            return publication
        end
        yield()
    end
end

function async_add_destination(c::Client, p::Publication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_add_destination(async, c.client, p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function async_remove_destination(c::Client, p::Publication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_remove_destination(async, c.client, p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function async_remove_destination_by_id(c::Client, p::Publication, destination_id)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_remove_destination_by_id(async, c.client, p.publication, destination_id) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function poll(::Publication, a::AsyncDestination)
    destination = Ref{Ptr{aeron_destination_t}}(C_NULL)
    retval = aeron_publication_async_destination_poll(destination, a.async) < 0
    if retval < 0
        throwerror()
    end
    return retval > 0
end

function Base.close(p::Publication)
    if p.allocated == true
        if aeron_publication_close(p.publication, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
    p.publication = C_NULL
end

function offer(p::Publication, buffer::AbstractVector{UInt8},
    reserved_value_supplier::Union{Nothing,AbstractReservedValueSupplier}=nothing)
    if reserved_value_supplier === nothing
        aeron_publication_offer(p.publication, buffer, length(buffer), C_NULL, C_NULL)
    else
        aeron_publication_offer(p.publication, buffer, length(buffer),
            reserved_value_supplier_cfunction(reserved_value_supplier),
            reserved_value_supplier_clientd(reserved_value_supplier))
    end
end

function offer(p::Publication, buffers::AbstractVector{<:AbstractVector{UInt8}},
    reserved_value_supplier::Union{Nothing,AbstractReservedValueSupplier}=nothing)
    n = length(buffers)
    resize!(p.iovecs, n)
    GC.@preserve buffers begin
        for (i, buffer) in enumerate(buffers)
            @inbounds p.iovecs[i] = aeron_iovec_t(pointer(buffer), length(buffer))
        end
        if reserved_value_supplier === nothing
            aeron_publication_offerv(p.publication, p.iovecs, n, C_NULL, C_NULL)
        else
            aeron_publication_offerv(p.publication, p.iovecs, n,
                reserved_value_supplier_cfunction(reserved_value_supplier),
                reserved_value_supplier_clientd(reserved_value_supplier))
        end
    end
end

function try_claim(p::Publication, length)
    buffer_claim = Ref{aeron_buffer_claim_t}()
    position = aeron_publication_try_claim(p.publication, length, buffer_claim)
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end

    return BufferClaim(buffer_claim), position
end

channel(p::Publication) = unsafe_string(p.constants.channel)
original_registration_id(p::Publication) = p.constants.original_registration_id
registration_id(p::Publication) = p.constants.registration_id
max_possible_position(p::Publication) = p.constants.max_possible_position
position_bits_to_shift(p::Publication) = p.constants.position_bits_to_shift
term_buffer_length(p::Publication) = p.constants.term_buffer_length
max_message_length(p::Publication) = p.constants.max_message_length
max_payload_length(p::Publication) = p.constants.max_payload_length
stream_id(p::Publication) = p.constants.stream_id
session_id(p::Publication) = p.constants.session_id
initial_term_id(p::Publication) = p.constants.initial_term_id
publication_limit_counter_id(p::Publication) = p.constants.publication_limit_counter_id
channel_status_indicator_id(p::Publication) = p.constants.channel_status_indicator_id

channel_status(p::Publication) = aeron_publication_channel_status(p.publication) == 1 ? :active : :errored
position(p::Publication) = aeron_publication_position(p.publication)
position_limit(p::Publication) = aeron_publication_position_limit(p.publication)
Base.isopen(p::Publication) = !aeron_publication_is_closed(p.publication)
is_connected(p::Publication) = aeron_publication_is_connected(p.publication)

function Base.show(io::IO, ::MIME"text/plain", p::Publication)
    println(io, "Publication")
    println(io, "  channel: ", channel(p))
    println(io, "  stream_id: ", stream_id(p))
    println(io, "  session_id: ", session_id(p))
    println(io, "  position: ", position(p))
    println(io, "  position_limit: ", position_limit(p))
    println(io, "  is open: ", isopen(p))
    println(io, "  is connected: ", is_connected(p))
end
