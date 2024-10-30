const IOVECS_NUM = 4

mutable struct ExclusivePublication
    publication::Ptr{aeron_exclusive_publication_t}
    const constants::aeron_publication_constants_t
    const iovecs::Vector{aeron_iovec_t}
    const allocated::Bool
    function ExclusivePublication(publication::Ptr{aeron_exclusive_publication_t}, allocated::Bool=false)
        constants = Ref{aeron_publication_constants_t}()
        if aeron_exclusive_publication_constants(publication, constants) < 0
            throwerror()
        end
        finalizer(close, new(publication, constants[],
            sizehint!(aeron_iovec_t[], IOVECS_NUM; shrink=false), allocated))
    end
end

struct AsyncAddExclusivePublication
    async::Ptr{aeron_async_add_exclusive_publication_t}
end

function async_add_exclusive_publication(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_exclusive_publication_t}}(C_NULL)
    if aeron_async_add_exclusive_publication(async, c.client, uri, stream_id) < 0
        throwerror()
    end
    return AsyncAddExclusivePublication(async[])
end

function poll(a::AsyncAddExclusivePublication)
    publication = Ref{Ptr{aeron_exclusive_publication_t}}(C_NULL)
    if aeron_async_add_exclusive_publication_poll(publication, a.async) < 0
        throwerror()
    end
    if publication[] == C_NULL
        return nothing
    end
    return ExclusivePublication(publication[], true)
end

function add_exclusive_publication(c::Client, uri::AbstractString, stream_id)
    async = async_add_exclusive_publication(c, uri, stream_id)
    while true
        publication = poll(async)
        if publication !== nothing
            return publication
        end
        yield()
    end
end

function async_add_destination(c::Client, p::ExclusivePublication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_add_destination(async, c.client, p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function async_remove_destination(c::Client, p::ExclusivePublication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_remove_destination(async, c.client, p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function async_remove_destination_by_id(c::Client, p::ExclusivePublication, destination_id)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_remove_destination_by_id(async, c.client, p.publication, destination_id) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

function poll(::ExclusivePublication, a::AsyncDestination)
    destination = Ref{Ptr{aeron_destination_t}}(C_NULL)
    retval = aeron_exclusive_publication_async_destination_poll(destination, a.async) < 0
    if retval < 0
        throwerror()
    end
    return retval > 0
end

function Base.close(p::ExclusivePublication)
    if p.allocated == true
        if aeron_exclusive_publication_close(p.publication, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
    p.publication = C_NULL
end

function offer(p::ExclusivePublication, buffer::AbstractVector{UInt8},
    reserved_value_supplier::Union{Nothing,AbstractReservedValueSupplier}=nothing)
    if reserved_value_supplier === nothing
        aeron_exclusive_publication_offer(p.publication, buffer, length(buffer), C_NULL, C_NULL)
    else
        aeron_exclusive_publication_offer(p.publication, buffer, length(buffer),
            reserved_value_supplier_cfunction(reserved_value_supplier),
            reserved_value_supplier_clientd(reserved_value_supplier))
    end
end

function offer(p::ExclusivePublication, buffers::AbstractVector{<:AbstractVector{UInt8}},
    reserved_value_supplier::Union{Nothing,AbstractReservedValueSupplier}=nothing)
    n = length(buffers)
    resize!(p.iovecs, n)
    GC.@preserve buffers begin
        for (i, buffer) in enumerate(buffers)
            @inbounds p.iovecs[i] = aeron_iovec_t(pointer(buffer), length(buffer))
        end
        if reserved_value_supplier === nothing
            aeron_exclusive_publication_offerv(p.publication, p.iovecs, n, C_NULL, C_NULL)
        else
            aeron_exclusive_publication_offerv(p.publication, p.iovecs, n,
                reserved_value_supplier_cfunction(reserved_value_supplier),
                reserved_value_supplier_clientd(reserved_value_supplier))
        end
    end
end

function offer_block(p::ExclusivePublication, buffer::AbstractVector{UInt8})
    position = aeron_exclusive_publication_offer_block(p.publication, buffer, length(buffer))
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end
    return position
end

function try_claim(p::ExclusivePublication, length)
    buffer_claim = Ref{aeron_buffer_claim_t}()
    position = aeron_exclusive_publication_try_claim(p.publication, length, buffer_claim)
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end

    return BufferClaim(buffer_claim), position
end

channel(p::ExclusivePublication) = unsafe_string(p.constants.channel)
original_registration_id(p::ExclusivePublication) = p.constants.original_registration_id
registration_id(p::ExclusivePublication) = p.constants.registration_id
max_possible_position(p::ExclusivePublication) = p.constants.max_possible_position
position_bits_to_shift(p::ExclusivePublication) = p.constants.position_bits_to_shift
term_buffer_length(p::ExclusivePublication) = p.constants.term_buffer_length
max_message_length(p::ExclusivePublication) = p.constants.max_message_length
max_payload_length(p::ExclusivePublication) = p.constants.max_payload_length
stream_id(p::ExclusivePublication) = p.constants.stream_id
session_id(p::ExclusivePublication) = p.constants.session_id
initial_term_id(p::ExclusivePublication) = p.constants.initial_term_id
exclusive_publication_limit_counter_id(p::ExclusivePublication) = p.constants.exclusive_publication_limit_counter_id
channel_status_indicator_id(p::ExclusivePublication) = p.constants.channel_status_indicator_id

channel_status(p::ExclusivePublication) = aeron_exclusive_publication_channel_status(p.publication) == 1 ? :active : :errored
position(p::ExclusivePublication) = aeron_exclusive_publication_position(p.publication)
position_limit(p::ExclusivePublication) = aeron_exclusive_publication_position_limit(p.publication)
Base.isopen(p::ExclusivePublication) = !aeron_exclusive_publication_is_closed(p.publication)
is_connected(p::ExclusivePublication) = aeron_exclusive_publication_is_connected(p.publication)

function Base.show(io::IO, ::MIME"text/plain", p::ExclusivePublication)
    println(io, "ExclusivePublication")
    println(io, "  channel: ", channel(p))
    println(io, "  stream_id: ", stream_id(p))
    println(io, "  session_id: ", session_id(p))
    println(io, "  position: ", position(p))
    println(io, "  position_limit: ", position_limit(p))
    println(io, "  is open: ", isopen(p))
    println(io, "  is connected: ", is_connected(p))
end
