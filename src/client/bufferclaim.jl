"""
    struct BufferClaim

Represents a buffer claim in an Aeron publication.

After writing to the claimed buffer, call [`commit`](@ref) to publish the message or [`abort`](@ref) to cancel the claim.

"""
struct BufferClaim
    claim_ref::Base.RefValue{aeron_buffer_claim_t}
end

BufferClaim() = BufferClaim(Ref{aeron_buffer_claim_t}())

"""
    buffer(p::BufferClaim) -> UnsafeArray{UInt8,1}

Returns an `UnsafeArray` representing the buffer of the `BufferClaim` `p`.

Provides direct access to the memory buffer where the message should be written.

The size of the buffer is determined by the length of the claim.
"""
buffer(p::BufferClaim) = UnsafeArray(p.claim_ref[].data, (Int64(p.claim_ref[].length),))

"""
    commit(c::BufferClaim)

Commits the `BufferClaim` `c` after the message has been written to the buffer, making it available to subscribers.

Throws an error if the commit operation fails.
"""
function commit(c::BufferClaim)
    if aeron_buffer_claim_commit(c.claim_ref) < 0
        throwerror()
    end
end

"""
    abort(c::BufferClaim)

Aborts the `BufferClaim` `c`, canceling the claim and releasing the buffer without publishing the message.

Throws an error if the abort operation fails.
"""
function abort(c::BufferClaim)
    if aeron_buffer_claim_abort(c.claim_ref) < 0
        throwerror()
    end
end
