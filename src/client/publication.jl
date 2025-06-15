struct Publication
    publication::Ptr{aeron_publication_t}
    constants::aeron_publication_constants_t
    client::Client
    is_owned::Bool

    """
    Create a new `Publication` instance.

    # Arguments
    - `publication::Ptr{aeron_publication_t}`: Pointer to the Aeron publication.
    - `is_owned::Bool=false`: Indicates if the publication is owned by this instance.
    """
    function Publication(publication::Ptr{aeron_publication_t}, client::Client, is_owned::Bool=false)
        constants = Ref{aeron_publication_constants_t}()
        if aeron_publication_constants(publication, constants) < 0
            throwerror()
        end
        return new(publication, constants[], client, is_owned)
    end
end

struct AsyncAddPublication
    async::Ptr{aeron_async_add_publication_t}
    client::Client
end

"""
Initiate an asynchronous request to add a publication.

# Arguments
- `c::Client`: The client instance.
- `uri::AbstractString`: The URI of the publication.
- `stream_id`: The stream ID of the publication.

# Returns
- `AsyncAddPublication`: The asynchronous add publication request.
"""
function async_add_publication(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_publication_t}}(C_NULL)
    if aeron_async_add_publication(async, c.client, uri, stream_id) < 0
        throwerror()
    end
    return AsyncAddPublication(async[], c)
end

"""
Poll the status of an asynchronous add publication request.

# Arguments
- `a::AsyncAddPublication`: The asynchronous add publication request.

# Returns
- `Publication`: The publication if the request is complete.
- `nothing`: If the request is not yet complete.
"""
function poll(a::AsyncAddPublication)
    publication = Ref{Ptr{aeron_publication_t}}(C_NULL)
    if aeron_async_add_publication_poll(publication, a.async) < 0
        throwerror()
    end
    if publication[] == C_NULL
        return nothing
    end
    return Publication(publication[], a.client, true)
end

"""
Add a publication and wait for it to be available.

# Arguments
- `c::Client`: The client instance.
- `uri::AbstractString`: The URI of the publication.
- `stream_id`: The stream ID of the publication.

# Returns
- `Publication`: The publication.
"""
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

"""
Initiate an asynchronous request to add a destination to a publication.

# Arguments
- `p::Publication`: The publication.
- `uri::AbstractString`: The URI of the destination.
"""
function async_add_destination(p::Publication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_add_destination(async, pointer(p.client), p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Add a destination to a publication and wait for it to be available.

# Arguments
- `p::Publication`: The publication.
- `uri::AbstractString`: The URI of the destination.
"""
function add_destination(p::Publication, uri::AbstractString)
    async = async_add_destination(p, uri)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Initiate an asynchronous request to remove a destination to a publication.

# Arguments
- `p::Publication`: The publication.
- `uri::AbstractString`: The URI of the destination.
"""
function async_remove_destination(p::Publication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_remove_destination(async, pointer(p.client), p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Remove a destination from a publication.

# Arguments
- `p::Publication`: The publication.
- `uri::AbstractString`: The URI of the destination.
"""
function remove_destination(p::Publication, uri::AbstractString)
    async = async_remove_destination(p, uri)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Initiate an asynchronous request to remove a destination to a publication by ID.

# Arguments
- `p::Publication`: The publication.
- `destination_id`: The ID of the destination.
"""
function async_remove_destination_by_id(p::Publication, destination_id)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_publication_async_remove_destination_by_id(async, pointer(p.client), p.publication, destination_id) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Remove a destination from a publication by ID.

# Arguments
- `p::Publication`: The publication.
- `destination_id`: The ID of the destination.
"""
function remove_destination_by_id(p::Publication, destination_id)
    async = async_remove_destination_by_id(p, destination_id)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Poll the status of an asynchronous destination request.

# Arguments
- `p::Publication`: The publication.
- `a::AsyncDestination`: The asynchronous destination request.

# Returns
- `Bool`: `true` if the request is complete, `false` otherwise.
"""
function poll(::Publication, a::AsyncDestination)
    retval = aeron_publication_async_destination_poll(a.async)
    if retval < 0
        throwerror()
    end
    return retval > 0
end

"""
Close the publication.

# Arguments
- `p::Publication`: The publication to close.
"""
function Base.close(p::Publication)
    if p.is_owned == true
        if aeron_publication_close(p.publication, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
end

"""
    offer(p::Publication, buffer::AbstractVector{UInt8}) -> Int

Offer a buffer to the publication.

# Arguments
- `p::Publication`: The publication.
- `buffer::AbstractVector{UInt8}`: The buffer to offer.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::Publication, buffer::AbstractVector{UInt8})
    aeron_publication_offer(p.publication, buffer, length(buffer), C_NULL, C_NULL)
end

"""
    offer(p::Publication, buffer::AbstractVector{UInt8}, reserved_value_supplier::AbstractReservedValueSupplier) -> Int

Offer a buffer to the publication with a reserved value supplier.

# Arguments
- `p::Publication`: The publication.
- `buffer::AbstractVector{UInt8}`: The buffer to offer.
- `reserved_value_supplier::AbstractReservedValueSupplier`: The reserved value supplier.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::Publication, buffer::AbstractVector{UInt8}, reserved_value_supplier::AbstractReservedValueSupplier)
    GC.@preserve reserved_value_supplier begin
        aeron_publication_offer(p.publication, buffer, length(buffer),
            reserved_value_supplier_cfunction(reserved_value_supplier),
            Ref(reserved_value_supplier))
    end
end

"""
    offer(p::Publication, buffers::Union{NTuple{N,T},AbstractVector{T}}) where {T<:AbstractVector{UInt8},N} -> Int

Offer multiple buffers to the publication.

# Arguments
- `p::Publication`: The publication.
- `buffers::buffers::Union{NTuple{N,T},AbstractVector{T}}`: The buffers to offer.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::Publication, buffers::Union{NTuple{N,T},AbstractVector{T}}) where {T<:AbstractVector{UInt8},N}
    _offer(p, buffers, C_NULL, C_NULL)
end

"""
    offer(p::Publication, buffers::AbstractVector{<:AbstractVector{UInt8}}, reserved_value_supplier::AbstractReservedValueSupplier) -> Int

Offer multiple buffers to the publication with a reserved value supplier.

# Arguments
- `p::Publication`: The publication.
- `buffers::AbstractVector{<:AbstractVector{UInt8}}`: The buffers to offer.
- `reserved_value_supplier::AbstractReservedValueSupplier`: The reserved value supplier.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::Publication,
    buffers::Union{NTuple{N,T},AbstractVector{T}},
    reserved_value_supplier::AbstractReservedValueSupplier) where {T<:AbstractVector{UInt8},N}
    _offer(p, buffers, reserved_value_supplier_cfunction(reserved_value_supplier), Ref(reserved_value_supplier))
end

function _offer(p::Publication,
    buffers::Union{NTuple{N,T},AbstractVector{T}},
    reserved_value_supplier,
    clientd) where {T<:AbstractVector{UInt8},N}

    n = length(buffers)

    GC.@preserve buffers begin
        iovecs = ntuple(n) do i
            buffer = buffers[i]
            aeron_iovec_t(Base.pointer(buffer), Base.length(buffer))
        end

        position = aeron_publication_offerv(p.publication, Ref(iovecs), n, reserved_value_supplier, clientd)
        return Int(position)
    end
end

"""
Try to claim a range of the publication.

# Arguments
- `p::Publication`: The publication.
- `length`: The length of the range to claim.

# Returns
- `BufferClaim`: The buffer claim.
- `Int`: The new stream position otherwise a negative error value.
"""
@inline function try_claim(p::Publication, length)
    buffer_claim = Ref{aeron_buffer_claim_t}()
    position = aeron_publication_try_claim(p.publication, length, buffer_claim)
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end

    return BufferClaim(buffer_claim[]), Int(position)
end

"""
Get the channel of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `String`: The channel of the publication.
"""
channel(p::Publication) = unsafe_string(p.constants.channel)

"""
Get the original registration ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The original registration ID of the publication.
"""
original_registration_id(p::Publication) = p.constants.original_registration_id

"""
Get the registration ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The registration ID of the publication.
"""
registration_id(p::Publication) = p.constants.registration_id

"""
Get the maximum possible position of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The maximum possible position of the publication.
"""
max_possible_position(p::Publication) = p.constants.max_possible_position

"""
Get the position bits to shift of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The position bits to shift of the publication.
"""
position_bits_to_shift(p::Publication) = p.constants.position_bits_to_shift

"""
Get the term buffer length of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The term buffer length of the publication.
"""
term_buffer_length(p::Publication) = p.constants.term_buffer_length

"""
Get the maximum message length of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The maximum message length of the publication.
"""
max_message_length(p::Publication) = p.constants.max_message_length

"""
Get the maximum payload length of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The maximum payload length of the publication.
"""
max_payload_length(p::Publication) = p.constants.max_payload_length

"""
Get the stream ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The stream ID of the publication.
"""
stream_id(p::Publication) = p.constants.stream_id

"""
Get the session ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The session ID of the publication.
"""
session_id(p::Publication) = p.constants.session_id

"""
Get the initial term ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The initial term ID of the publication.
"""
initial_term_id(p::Publication) = p.constants.initial_term_id

"""
Get the publication limit counter ID.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The publication limit counter ID.
"""
publication_limit_counter_id(p::Publication) = p.constants.publication_limit_counter_id

"""
Get the channel status indicator ID of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The channel status indicator ID of the publication.
"""
channel_status_indicator_id(p::Publication) = p.constants.channel_status_indicator_id

"""
Get the channel status of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Symbol`: `:active` if the channel is active, `:errored` otherwise.
"""
channel_status(p::Publication) = aeron_publication_channel_status(p.publication) == 1 ? :active : :errored

"""
Get the position of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The position of the publication.
"""
position(p::Publication) = aeron_publication_position(p.publication)

"""
Get the position limit of the publication.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Int`: The position limit of the publication.
"""
position_limit(p::Publication) = aeron_publication_position_limit(p.publication)

"""
Check if the publication is open.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Bool`: `true` if the publication is open, `false` otherwise.
"""
Base.isopen(p::Publication) = !aeron_publication_is_closed(p.publication)

"""
Check if the publication is connected.

# Arguments
- `p::Publication`: The publication.

# Returns
- `Bool`: `true` if the publication is connected, `false` otherwise.
"""
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
