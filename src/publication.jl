const PUBLICATION_NOT_CONNECTED = AERON_PUBLICATION_NOT_CONNECTED
const PUBLICATION_BACK_PRESSURED = AERON_PUBLICATION_BACK_PRESSURED
const PUBLICATION_ADMIN_ACTION = AERON_PUBLICATION_ADMIN_ACTION
const PUBLICATION_CLOSED = AERON_PUBLICATION_CLOSED
const PUBLICATION_MAX_POSITION_EXCEEDED = AERON_PUBLICATION_MAX_POSITION_EXCEEDED
const PUBLICATION_ERROR = AERON_PUBLICATION_ERROR

mutable struct Publication
    publication::Ptr{aeron_publication_t}
    const constants::aeron_publication_constants_t
    function Publication(publication::Ptr{aeron_publication_t})
        constants = Ref{aeron_publication_constants_t}()
        if aeron_publication_constants(publication, constants) < 0
            throwerror()
        end
        finalizer(close, new(publication, constants[]))
    end
end

function add_publication(c::Client, uri::AbstractString, stream_id)
    async = Ref{Ptr{aeron_async_add_publication_t}}(C_NULL)
    publication = Ref{Ptr{aeron_publication_t}}(C_NULL)
    try
        if aeron_async_add_publication(async, c.client, uri, stream_id) < 0
            throwerror()
        end

        while publication[] == C_NULL
            if aeron_async_add_publication_poll(publication, async[]) < 0
                throwerror()
            end
            yield()
        end
        return Publication(publication[])
    catch e
        if publication[] != C_NULL
            aeron_publication_close(publication[], C_NULL, C_NULL)
        end
        throw(e)
    end
end

function Base.close(p::Publication)
    ccall(:jl_safe_printf, Cvoid, (Cstring, Cstring), "Finalizing %s.\n", repr(p))
    if aeron_publication_close(p.publication, C_NULL, C_NULL) < 0
        throwerror()
    end
end

function offer(p::Publication, data::AbstractArray{UInt8})
    aeron_publication_offer(p.publication, data, length(data), C_NULL, C_NULL)
end

function offerv(p::Publication, data::AbstractVector{<:AbstractVector{UInt8}})
    iovecs = [aeron_iovec_t(pointer(vec), length(vec)) for vec in data]
    aeron_publication_offerv(p.publication, iovecs, length(iovecs), C_NULL, C_NULL)
end

function tryclaim(p::Publication, length)
    c = Ref{aeron_buffer_claim_t}()
    position = aeron_publication_try_claim(p.publication, length, c)
    if position == AERON_PUBLICATION_ERROR
        throwerror()
    end

    return BufferClaim(c), position
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
isconnected(p::Publication) = aeron_publication_is_connected(p.publication)
