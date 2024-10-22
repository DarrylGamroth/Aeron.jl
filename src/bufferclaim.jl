struct BufferClaim
    claim::Ref{aeron_buffer_claim_t}
end

buffer(p::BufferClaim) = UnsafeArray(p.claim[].data, (Int64(p.claim[].length),))

function commit(c::BufferClaim)
    if aeron_buffer_claim_commit(c.claim) < 0
        throwerror()
    end
end

function abort(c::BufferClaim)
    if aeron_buffer_claim_abort(c.claim) < 0
        throwerror()
    end
end