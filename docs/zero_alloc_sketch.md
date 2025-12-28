# Zero-Allocation Publish Sketch (Julia)

## Goal

Match the C++ wrapper's zero-allocation intent while keeping Aeron.jl's API clean and free of exposed C pointers.

## Constraints (Why Julia Differs)

- C/C++ can always stack-allocate `aeron_iovec_t` and pass `&iov[0]` to C.
- Julia does not guarantee stack allocation for temporaries used in `ccall`, and any `Ref(...)` or `ntuple(...)` used to pass data to C will allocate on the heap once the data "escapes".
- A `Vector{aeron_iovec_t}` is the only safe, stable, contiguous memory to pass as `Ptr{aeron_iovec_t}` for variable-length iovec arrays.

## Design Sketch (Clean, Reuse-Oriented APIs)

### 1) Reusable iovec offer

Add an allocation-free variant that reuses internal scratch space:

```
# API (sketch)

"""
    offer!(p::Publication,
           buffers::Union{NTuple{N,T},AbstractVector{T}}) where {T<:AbstractVector{UInt8},N} -> Int

Offer multiple buffers using the publication's preallocated iovec scratch space.
"""

"""
    offer!(p::Publication,
           buffers::Union{NTuple{N,T},AbstractVector{T}},
           reserved_value_supplier::AbstractReservedValueSupplier) where {T<:AbstractVector{UInt8},N} -> Int

Offer multiple buffers with a reserved value supplier using the publication's preallocated iovec scratch space.
"""
```

Internal (non-exported) storage on `Publication`:

```
# fields on Publication (sketch)
_iovecs::Vector{aeron_iovec_t}
```

Implementation approach:

- resize or sizehint `_iovecs` once and reuse
- fill `_iovecs[i] = aeron_iovec_t(pointer(buf), length(buf))`
- call `aeron_publication_offerv(p.publication, pointer(_iovecs), n, ...)`

This mirrors the C++ `std::vector<aeron_iovec_t>` reuse strategy.

### 2) Reusable try_claim

Expose an allocation-free claim path by letting `BufferClaim` own a reusable `Ref`:

```
# API (sketch)

struct BufferClaim
    claim_ref::Base.RefValue{aeron_buffer_claim_t}
end

try_claim(p::Publication, length, claim::BufferClaim) -> Int
commit(claim::BufferClaim)
abort(claim::BufferClaim)
```

`BufferClaim` is a lightweight wrapper holding the `RefValue` and exposing `buffer`, `commit`, `abort`.

This mirrors the C++ `BufferClaim&` reuse path (each thread reuses its own `BufferClaim`).

## Thread Safety Note

If scratch storage is on `Publication`, `offer!` is not safe for concurrent use on the same publication instance. If multi-threaded publishers are required, each thread should own a publication or an external scratch bundle.

## Alternative: External Scratch Bundle

If keeping `Publication` immutable is preferred, use an explicit scratch type:

```
# API (sketch)

struct PublicationScratch
    iovecs::Vector{aeron_iovec_t}
    claim::BufferClaim
end

offer!(p::Publication, buffers, scratch::PublicationScratch)
try_claim(p::Publication, length, scratch::PublicationScratch)
```

This keeps allocation-free behavior explicit and thread-safe by construction.

## C++ Wrapper Notes

The C++ wrapper uses stack `aeron_buffer_claim_t temp_claim;` in `tryClaim` and a heap-backed `std::vector<aeron_iovec_t>` for scatter/gather. It is allocation-free in the claim path and typically amortized allocation in the iovec path.
