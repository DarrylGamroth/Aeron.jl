struct ExclusivePublication
    publication::Ptr{aeron_exclusive_publication_t}
    constants::aeron_publication_constants_t
    client::Client
    is_owned::Bool

    """
    Create a new `ExclusivePublication` instance.

    # Arguments
    - `publication::Ptr{aeron_exclusive_publication_t}`: Pointer to the Aeron exclusive publication.
    - `is_owned::Bool=false`: Indicates if the publication is owned by this instance.
    """
    function ExclusivePublication(publication::Ptr{aeron_exclusive_publication_t}, client::Client, is_owned::Bool=false)
        constants = Ref{aeron_publication_constants_t}()
        if aeron_exclusive_publication_constants(publication, constants) < 0
            throwerror()
        end
        return new(publication, constants[], client, is_owned)
    end
end

struct AsyncAddExclusivePublication
    async::Ptr{aeron_async_add_exclusive_publication_t}
    client::Client
end

"""
Initiate an asynchronous request to add an exclusive publication.

# Arguments
- `c::Client`: The client instance.
- `uri::AbstractString`: The URI of the publication.
- `stream_id`: The stream ID of the publication.

# Returns
- `AsyncAddExclusivePublication`: The asynchronous add exclusive publication request.
"""
function async_add_exclusive_publication(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_exclusive_publication_t}}(C_NULL)
    if aeron_async_add_exclusive_publication(async, c.client, uri, stream_id) < 0
        throwerror()
    end
    return AsyncAddExclusivePublication(async[], c)
end

"""
Poll the status of an asynchronous add exclusive publication request.

# Arguments
- `a::AsyncAddExclusivePublication`: The asynchronous add exclusive publication request.

# Returns
- `ExclusivePublication`: The exclusive publication if the request is complete.
- `nothing`: If the request is not yet complete.
"""
function poll(a::AsyncAddExclusivePublication)
    publication = Ref{Ptr{aeron_exclusive_publication_t}}(C_NULL)
    if aeron_async_add_exclusive_publication_poll(publication, a.async) < 0
        throwerror()
    end
    if publication[] == C_NULL
        return nothing
    end
    return ExclusivePublication(publication[], a.client, true)
end

"""
Add an exclusive publication and wait for it to be available.

# Arguments
- `c::Client`: The client instance.
- `uri::AbstractString`: The URI of the publication.
- `stream_id`: The stream ID of the publication.

# Returns
- `ExclusivePublication`: The exclusive publication.
"""
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

"""
Initiate an asynchronous request to add a destination to an exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `uri::AbstractString`: The URI of the destination.
"""
function async_add_destination(p::ExclusivePublication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_add_destination(async, pointer(p.client), p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Add a destination to an exclusive publication and wait for it to be available.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `uri::AbstractString`: The URI of the destination.
"""
function add_destination(p::ExclusivePublication, uri::AbstractString)
    async = async_add_destination(p, uri)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Initiate an asynchronous request to remove a destination to an exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `uri::AbstractString`: The URI of the destination.
"""
function async_remove_destination(p::ExclusivePublication, uri::AbstractString)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_remove_destination(async, pointer(p.client), p.publication, uri) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Remove a destination from an exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `uri::AbstractString`: The URI of the destination.
"""
function remove_destination(p::ExclusivePublication, uri::AbstractString)
    async = async_remove_destination(p, uri)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Initiate an asynchronous request to remove a destination to an exclusive publication by ID.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `destination_id`: The ID of the destination.
"""
function async_remove_destination_by_id(p::ExclusivePublication, destination_id)
    async = Ref{Ptr{aeron_async_destination_t}}(C_NULL)
    if aeron_exclusive_publication_async_remove_destination_by_id(async, pointer(p.client), p.publication, destination_id) < 0
        throwerror()
    end
    return AsyncDestination(async[])
end

"""
Remove a destination from an exclusive publication by ID.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `destination_id`: The ID of the destination.
"""
function remove_destination_by_id(p::ExclusivePublication, destination_id)
    async = async_remove_destination_by_id(p, destination_id)
    while true
        poll(p, async) && return
        yield()
    end
end

"""
Poll the status of an asynchronous destination request.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `a::AsyncDestination`: The asynchronous destination request.

# Returns
- `Bool`: `true` if the request is complete, `false` otherwise.
"""
function poll(::ExclusivePublication, a::AsyncDestination)
    retval = aeron_exclusive_publication_async_destination_poll(a.async)
    if retval < 0
        throwerror()
    end
    return retval > 0
end

"""
Close the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication to close.
"""
function Base.close(p::ExclusivePublication)
    if p.is_owned == true
        if aeron_exclusive_publication_close(p.publication, C_NULL, C_NULL) < 0
            throwerror()
        end
    end
end

"""
    offer(p::ExclusivePublication, buffer::AbstractVector{UInt8}) -> Int

Offer a buffer to the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `buffer::AbstractVector{UInt8}`: The buffer to offer.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::ExclusivePublication, buffer::AbstractVector{UInt8})
    aeron_exclusive_publication_offer(p.publication, buffer, length(buffer), C_NULL, C_NULL)
end

"""
    offer(p::ExclusivePublication, buffer::AbstractVector{UInt8}, reserved_value_supplier::AbstractReservedValueSupplier) -> Int

Offer a buffer to the exclusive publication with a reserved value supplier.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `buffer::AbstractVector{UInt8}`: The buffer to offer.
- `reserved_value_supplier::AbstractReservedValueSupplier`: The reserved value supplier.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::ExclusivePublication, buffer::AbstractVector{UInt8},
    reserved_value_supplier::AbstractReservedValueSupplier)
    GC.@preserve reserved_value_supplier begin
        aeron_exclusive_publication_offer(p.publication, buffer, length(buffer),
            reserved_value_supplier_cfunction(reserved_value_supplier),
            Ref(reserved_value_supplier))
    end
end

"""
    offer(p::ExclusivePublication, buffers::Union{NTuple{N,T},AbstractVector{T}}) where {T<:AbstractVector{UInt8},N}

Offer multiple buffers to the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `buffers::Union{NTuple{N,T},AbstractVector{T}}`: The buffers to offer.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::ExclusivePublication, buffers::Union{NTuple{N,T},AbstractVector{T}}) where {T<:AbstractVector{UInt8},N}
    _offer(p, buffers, C_NULL, C_NULL)
end

"""
    offer(p::ExclusivePublication, buffers::AbstractVector{<:AbstractVector{UInt8}}, reserved_value_supplier::AbstractReservedValueSupplier) -> Int

Offer multiple buffers to the exclusive publication with a reserved value supplier.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `buffers::AbstractVector{<:AbstractVector{UInt8}}`: The buffers to offer.
- `reserved_value_supplier::AbstractReservedValueSupplier`: The reserved value supplier.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer(p::ExclusivePublication,
    buffers::Union{NTuple{N,T},AbstractVector{T}},
    reserved_value_supplier::AbstractReservedValueSupplier) where {T<:AbstractVector{UInt8},N}
    _offer(p, buffers, reserved_value_supplier_cfunction(reserved_value_supplier), Ref(reserved_value_supplier))
end

function _offer(p::ExclusivePublication,
    buffers::Union{NTuple{N,T},AbstractVector{T}},
    reserved_value_supplier,
    clientd) where {T<:AbstractVector{UInt8},N}

    n = length(buffers)

    GC.@preserve buffers begin
        iovecs = ntuple(n) do i
            buffer = buffers[i]
            aeron_iovec_t(Base.pointer(buffer), Base.length(buffer))
        end

        position = aeron_exclusive_publication_offerv(p.publication, iovecs, n, reserved_value_supplier, clientd)
        return position
    end
end

"""
Offer a block of data to the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `buffer::AbstractVector{UInt8}`: The buffer to offer.

# Returns
- `Int`: The new stream position otherwise a negative error value.
"""
function offer_block(p::ExclusivePublication, buffer::AbstractVector{UInt8})
    position = aeron_exclusive_publication_offer_block(p.publication, buffer, length(buffer))
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end
    return position
end

"""
Try to claim a range of the publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.
- `length`: The length of the range to claim.

# Returns
- `BufferClaim`: The buffer claim.
- `Int`: The new stream position otherwise a negative error value.
"""
@inline function try_claim(p::ExclusivePublication, length)
    buffer_claim = Ref{aeron_buffer_claim_t}()
    position = aeron_exclusive_publication_try_claim(p.publication, length, buffer_claim)
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end

    return BufferClaim(buffer_claim[]), position
end

"""
Get the channel of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `String`: The channel of the exclusive publication.
"""
channel(p::ExclusivePublication) = unsafe_string(p.constants.channel)

"""
Get the original registration ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The original registration ID of the exclusive publication.
"""
original_registration_id(p::ExclusivePublication) = p.constants.original_registration_id

"""
Get the registration ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The registration ID of the exclusive publication.
"""
registration_id(p::ExclusivePublication) = p.constants.registration_id

"""
Get the maximum possible position of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The maximum possible position of the exclusive publication.
"""
max_possible_position(p::ExclusivePublication) = p.constants.max_possible_position

"""
Get the position bits to shift of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The position bits to shift of the exclusive publication.
"""
position_bits_to_shift(p::ExclusivePublication) = p.constants.position_bits_to_shift

"""
Get the term buffer length of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The term buffer length of the exclusive publication.
"""
term_buffer_length(p::ExclusivePublication) = p.constants.term_buffer_length

"""
Get the maximum message length of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The maximum message length of the exclusive publication.
"""
max_message_length(p::ExclusivePublication) = p.constants.max_message_length

"""
Get the maximum payload length of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The maximum payload length of the exclusive publication.
"""
max_payload_length(p::ExclusivePublication) = p.constants.max_payload_length

"""
Get the stream ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The stream ID of the exclusive publication.
"""
stream_id(p::ExclusivePublication) = p.constants.stream_id

"""
Get the session ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The session ID of the exclusive publication.
"""
session_id(p::ExclusivePublication) = p.constants.session_id

"""
Get the initial term ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The initial term ID of the exclusive publication.
"""
initial_term_id(p::ExclusivePublication) = p.constants.initial_term_id

"""
Get the exclusive publication limit counter ID.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The exclusive publication limit counter ID.
"""
exclusive_publication_limit_counter_id(p::ExclusivePublication) = p.constants.exclusive_publication_limit_counter_id

"""
Get the channel status indicator ID of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The channel status indicator ID of the exclusive publication.
"""
channel_status_indicator_id(p::ExclusivePublication) = p.constants.channel_status_indicator_id

"""
Get the channel status of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Symbol`: `:active` if the channel is active, `:errored` otherwise.
"""
channel_status(p::ExclusivePublication) = aeron_exclusive_publication_channel_status(p.publication) == 1 ? :active : :errored

"""
Get the position of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The position of the exclusive publication.
"""
position(p::ExclusivePublication) = aeron_exclusive_publication_position(p.publication)

"""
Get the position limit of the exclusive publication.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Int`: The position limit of the exclusive publication.
"""
position_limit(p::ExclusivePublication) = aeron_exclusive_publication_position_limit(p.publication)

"""
Check if the exclusive publication is open.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Bool`: `true` if the exclusive publication is open, `false` otherwise.
"""
Base.isopen(p::ExclusivePublication) = !aeron_exclusive_publication_is_closed(p.publication)

"""
Check if the exclusive publication is connected.

# Arguments
- `p::ExclusivePublication`: The exclusive publication.

# Returns
- `Bool`: `true` if the exclusive publication is connected, `false` otherwise.
"""
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
