"""
    struct BufferClaim

Represents a buffer claim in an Aeron publication.

`BufferClaim` holds a reference to an `aeron_buffer_claim_t` structure, enabling zero-copy message encoding when publishing messages.

After writing to the claimed buffer, call [`commit`](@ref) to publish the message or [`abort`](@ref) to cancel the claim.

# Fields

- `claim::Ref{aeron_buffer_claim_t}`: Reference to the underlying Aeron buffer claim structure.
"""
struct BufferClaim
    claim::Ref{aeron_buffer_claim_t}
end

"""
    buffer(p::BufferClaim) -> UnsafeArray{UInt8,1}

Returns an `UnsafeArray` representing the buffer of the `BufferClaim` `p`.

Provides direct access to the memory buffer where the message should be written.

The size of the buffer is determined by the length of the claim.
"""
buffer(p::BufferClaim) = UnsafeArray(p.claim[].data, (Int64(p.claim[].length),))

"""
    commit(c::BufferClaim)

Commits the `BufferClaim` `c` after the message has been written to the buffer, making it available to subscribers.

Throws an error if the commit operation fails.
"""
function commit(c::BufferClaim)
    if aeron_buffer_claim_commit(c.claim) < 0
        throwerror()
    end
end

"""
    abort(c::BufferClaim)

Aborts the `BufferClaim` `c`, canceling the claim and releasing the buffer without publishing the message.

Throws an error if the abort operation fails.
"""
function abort(c::BufferClaim)
    if aeron_buffer_claim_abort(c.claim) < 0
        throwerror()
    end
end
