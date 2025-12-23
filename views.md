# Non-allocating Views in Aeron.jl

This document describes a potential non-allocating "view" API for Aeron.jl. The goal is to avoid heap allocations in hot paths (callbacks, tight polls) while staying idiomatic to both Julia and the Aeron C API.

## What is a "view"?

A view is a lightweight object that references Aeron-owned memory (pointers and lengths) instead of copying it into Julia-owned heap objects. The view:

- Holds raw pointers plus lengths and/or metadata.
- Does not allocate Strings or Arrays unless the user explicitly asks.
- Is valid only while the underlying Aeron memory remains valid.
- Is intended for short-lived, callback-scoped usage.

## Why use views?

- Aeron callbacks can be extremely hot; allocations in these callbacks cause GC pressure.
- Many callback fields are strings or buffers that Aeron already owns.
- Copying these into Julia types is convenient but not always required.

## Design principles

- Provide *allocating* convenience APIs (current behavior) and *view* APIs side-by-side.
- Make lifetime constraints explicit in docstrings.
- Use Julia types that emphasize borrowing (e.g., `StringView`, `UnsafeArray`) to reduce accidental retention.
- Keep the C callback signatures unchanged.

## Example: ImageView

Today, subscription callbacks create an `Image` which allocates and stores metadata. A view-based callback would avoid that allocation.

Possible type:

```julia
struct ImageView
    image::Ptr{aeron_image_t}
    subscription::Ptr{aeron_subscription_t}
    client::Client
    constants::aeron_image_constants_t
end
```

Construction would load constants once (still no heap allocations):

```julia
function ImageView(image::Ptr{aeron_image_t}, subscription::Ptr{aeron_subscription_t}, client::Client)
    constants = Ref{aeron_image_constants_t}()
    if aeron_image_constants(image, constants) < 0
        throwerror()
    end
    return ImageView(image, subscription, client, constants[])
end
```

Then in the callback wrapper:

```julia
callback(ImageView(image, subscription, client))
```

This avoids allocating a Julia `Image` object and avoids `String` allocations.

### Accessors

Accessors should return scalars directly and use `StringView` for strings:

```julia
source_identity(view::ImageView) = StringView(UnsafeArray(view.constants.source_identity, (Int(view.constants.source_identity_length),)))
```

If an allocating `String` is needed, provide a helper:

```julia
source_identity_string(view::ImageView) = String(source_identity(view))
```

### Lifetime

An `ImageView` is only valid during the callback that created it. Do not store it or any `StringView` derived from it beyond the callback.

### Detailed usage example (fragment assembly)

Most users handle message data via fragment handlers/assemblers rather than direct `Image` access. A view-based API would focus on the handler hot path and only touch the view when needed (e.g., logging `source_identity` once per session).

Sketch of a view-friendly flow:

```julia
# Pseudocode: variant API for subscriptions that provides ImageView in the
# availability callbacks, while fragment handling stays the same.

sub = add_subscription(client, channel, stream_id;
    on_available_image = (imgv, _) -> begin
        # Only allocate if needed; otherwise keep it view-only.
        @info "image available" source=source_identity(imgv)
    end)

handler = FragmentAssembler(FragmentHandler() do buffer, header, _clientd
    # Pure hot path: operate on the fragment buffer and header only.
    # No Image allocation involved.
    process(buffer, header)
end)

poll(sub, handler, 10)
```

The key idea: keep fragment processing allocation-free and only use views in the less frequent lifecycle callbacks (available/unavailable image events).

## Other places where views help

Views are generally useful anywhere the current API eagerly allocates strings:

1. Recording descriptors
   - `RecordingDescriptor` and `RecordingSubscriptionDescriptor` currently call `unsafe_string` on each field.
   - A `RecordingDescriptorView` could expose `StringView` fields and avoid allocations in listing APIs.

2. Archive counters
   - `source_identity` in `archive.jl` currently allocates a buffer and `String` per call.
   - Provide `source_identity!(buf, ...)` as an "into" API, or a view that exposes the underlying buffer slice.

3. Counter labels and metadata
   - `counter_label` currently allocates a `Vector{UInt8}` and `String` per call.
   - A `counter_label!` that fills a caller-provided buffer can be used in hot loops.

4. Error/loss report readers (CnC)
   - The CnC callbacks already use `StringView` for error/channel/source strings.
   - This is a good example of a view-style API already in use.

### CnC example (view-style callbacks today)

The current CnC callbacks already follow the view pattern: they pass `StringView` values that reference Aeron-owned memory. This is a concrete example of a non-allocating view API.

```julia
cnc = CnC()

error_log_read(cnc) do observation_count, first_ts, last_ts, msg, _
    # msg is a StringView, no allocation unless you call String(msg)
    @debug "driver error" observation_count first_ts last_ts msg
end

loss_report_read(cnc) do observation_count, total_lost, first_ts, last_ts,
    session_id, stream_id, channel, source, _
    # channel/source are StringView values
    @debug "loss report" observation_count total_lost session_id stream_id channel source
end
```

## Idiomatic Julia considerations

- Julia has precedent for view types (e.g., `SubArray`, `StringView`, `UnsafeArray`).
- Returning `StringView` and `UnsafeArray` is idiomatic for non-owning references.
- Provide a clear, allocating fallback for ergonomic use (`String`, `Vector{UInt8}`).

## Alignment with Aeron API

- Aeron’s C API exposes pointers and lengths; views map naturally to that model.
- Aeron expects callbacks to be short-lived; view lifetimes align with Aeron’s semantics.
- Aeron often requires callers to copy data if it needs to be retained, which maps cleanly to explicit conversion helpers in Julia.

## Proposed API shape (sketch)

- `ImageView` (non-allocating)
- `RecordingDescriptorView` / `RecordingSubscriptionDescriptorView`
- `*_into!` functions for strings/buffers where Aeron fills caller memory

Example dual API:

```julia
# Existing allocating API
image_by_session_id(...) -> Image

# New view API
image_by_session_id_view(...) -> ImageView
```

Or callback variants:

```julia
on_available_image!(callback::Function, ...)
# callback receives Image (allocating)

on_available_image_view!(callback::Function, ...)
# callback receives ImageView (non-allocating)
```

## Safety notes

- Views must not escape the callback or be stored for later use.
- If data must persist, call explicit `String(...)` or `copy(...)` helpers.
- Document lifetime constraints clearly in each view type’s docstring.

## Docstrings should detail usage

When adding view APIs, docstrings should explicitly cover:\n
- Lifetime: \"valid only during the callback\" (or equivalent).\n
- Allocation behavior: what is borrowed vs what allocates.\n
- A short usage snippet showing the intended pattern.\n

Example docstring style:\n

```julia
\"\"\"
    on_available_image_view!(callback, subscription)

Register a callback that receives `ImageView` values (non-allocating).
The view is valid only for the duration of the callback.

Example:
    on_available_image_view!(sub) do imgv
        @info \"source\" source_identity(imgv)
    end
\"\"\"
```
