# Aeron.jl usage

This package wraps the Aeron C client and archive client. The core workflow is:

1) Start or connect to a media driver.
2) Create a `Context` and `Client`.
3) Add publications/subscriptions, then offer/poll.
4) Close resources when finished.

Most wrapper calls throw an `ErrorException` when the underlying C call returns a negative error code.

## Quick start (embedded media driver)

```julia
using Aeron

Aeron.MediaDriver.launch_embedded() do driver
    Aeron.Context() do ctx
        Aeron.aeron_dir!(ctx, Aeron.MediaDriver.aeron_dir(driver))

        Aeron.Client(ctx) do client
            channel = "aeron:udp?endpoint=localhost:20121"
            stream_id = 1001

            sub = Aeron.add_subscription(client, channel, stream_id)
            pub = Aeron.add_publication(client, channel, stream_id)

            try
                while !Aeron.is_connected(pub)
                    yield()
                end

                handler = Aeron.FragmentHandler() do _, buffer, _
                    println("recv: ", String(buffer))
                end

                Aeron.offer(pub, Vector{UInt8}(codeunits("hello")))
                Aeron.poll(sub, handler, 10)
            finally
                close(pub)
                close(sub)
            end
        end
    end
end
```

## Using an external media driver

If you already run `aeronmd`, point the context at its directory:

```julia
using Aeron

Aeron.Context() do ctx
    Aeron.aeron_dir!(ctx, "/path/to/aeron")
    Aeron.Client(ctx) do client
        # add publications/subscriptions
    end
end
```

## Publication and subscription basics

```julia
channel = "aeron:udp?endpoint=localhost:20121"
stream_id = 1001

sub = Aeron.add_subscription(client, channel, stream_id)
pub = Aeron.add_publication(client, channel, stream_id)

try
    payload = Vector{UInt8}(codeunits("hello"))
    Aeron.offer(pub, payload)

    handler = Aeron.FragmentHandler() do _, buffer, header
        vals = Aeron.values(header)
        println("session: ", vals.frame.session_id)
        println("payload: ", String(buffer))
    end

    Aeron.poll(sub, handler, 10)
finally
    close(pub)
    close(sub)
end
```

## Invoker mode (client conductor)

If you want to drive the client conductor from your own agent loop instead of
letting Aeron spawn a thread, enable invoker mode and call `do_work` yourself.
See `samples/invoker_publisher.jl` for a complete example.

```julia
using Aeron

Aeron.Context() do ctx
    Aeron.use_conductor_agent_invoker!(ctx, true)

    Aeron.Client(ctx) do client
        channel = "aeron:udp?endpoint=localhost:20121"
        stream_id = 1001

        pub = Aeron.add_publication(client, channel, stream_id)
        while true
            work = Aeron.do_work(client)
            work == 0 && yield()

            result = Aeron.offer(pub, Vector{UInt8}(codeunits("hello")))
            result > 0 && break
        end
    end
end
```

### Fragment assembly

Use a `FragmentAssembler` to reassemble fragmented messages before delivery:

```julia
handler = Aeron.FragmentHandler((_, buffer, _) -> println(String(buffer)))
assembler = Aeron.FragmentAssembler(handler)
Aeron.poll(sub, assembler, 10)
```

### Controlled fragments

Use `ControlledFragmentHandler` if you need backpressure on fragments:

```julia
handler = Aeron.ControlledFragmentHandler() do _, buffer, _
    println(String(buffer))
    return Aeron.ControlledPollAction.CONTINUE
end
Aeron.poll(sub, handler, 10)
```

## Destinations (manual control mode)

```julia
sub = Aeron.add_subscription(client, "aeron:udp?control-mode=manual", stream_id)
Aeron.add_destination(sub, "aeron:udp?endpoint=localhost:20121")
```

## Images and lifecycle

Images returned by `image_by_session_id` or `image_at_index` must be closed when done.
Use the do-block form to guarantee cleanup:

```julia
Aeron.image_by_session_id(sub, session_id) do img
    println(Aeron.session_id(img))
end
```

## Non-allocating image views

For hot paths, you can register view callbacks that receive `ImageView` values.
These are non-allocating views into Aeron-owned memory and are only valid during
the callback that created them.

```julia
sub = Aeron.add_subscription_view(client, channel, stream_id;
    on_available_image = imgv -> begin
        # imgv is an ImageView; StringView values are non-allocating.
        println("source: ", Aeron.source_identity(imgv))
    end)
```

Do not store `ImageView` or any `StringView` derived from it beyond the callback.
If you need a stable value, call `String(...)` inside the callback.

### Async view subscriptions

```julia
async_sub = Aeron.async_add_subscription_view(client, channel, stream_id)
sub = Aeron.poll(async_sub)
```

The view semantics are the same as `add_subscription_view`: callbacks receive
`ImageView` values and must not retain them.

## CnC monitoring

You can attach to the CnC file for driver monitoring:

```julia
cnc = Aeron.CnC(; base_path=Aeron.MediaDriver.aeron_dir(driver))
println("heartbeat: ", Aeron.to_driver_heartbeat(cnc))

Aeron.error_log_read(cnc) do _, _, _, msg, _
    println("driver error: ", msg)
end

Aeron.loss_report_read(cnc) do _, _, _, _, _, _, channel, source, _
    println("loss: ", channel, " -> ", source)
end
```

## Reserved value supplier

```julia
supplier = Aeron.ReservedValueSupplier((_, _) -> Int64(42))
Aeron.offer(pub, payload, supplier)
```

## Zero-copy publishing with BufferClaim

```julia
claim = Aeron.BufferClaim()
position = Aeron.try_claim(pub, 128, claim)
if position > 0
    buf = Aeron.buffer(claim)
    buf[1:5] .= Vector{UInt8}(codeunits("hello"))
    Aeron.commit(claim)
else
    Aeron.abort(claim)
end
```

## Counters and CountersReader

```julia
counter = Aeron.add_counter(client, Int32(1001), UInt8[1,2,3,4], "my-counter")
reader = Aeron.CountersReader(client)

id = Aeron.counter_id(counter)
println(Aeron.counter_value(reader, id))

counter[] = 10
Aeron.increment!(counter)
Aeron.compare_and_set!(counter, 11, 99)

Aeron.counter_foreach((value, id, type_id, key, label, _) -> begin
    println("$id $label $value")
end, reader)
```

## Archive client (optional)

The archive client requires a running Archive service (e.g. `ArchivingMediaDriver`).
Configure archive context channels and connect through an Aeron client:

```julia
const AeronArchive = Aeron.AeronArchive

AeronArchive.Context() do archive_ctx
    AeronArchive.aeron_dir!(archive_ctx, aeron_dir)
    AeronArchive.control_request_channel!(archive_ctx, control_channel)
    AeronArchive.control_request_stream_id!(archive_ctx, control_stream_id)
    AeronArchive.control_response_channel!(archive_ctx, response_channel)
    AeronArchive.control_response_stream_id!(archive_ctx, response_stream_id)
    AeronArchive.recording_events_channel!(archive_ctx, events_channel)
    AeronArchive.recording_events_stream_id!(archive_ctx, events_stream_id)

    AeronArchive.client!(archive_ctx, client)

    AeronArchive.connect(archive_ctx) do archive
        pub = AeronArchive.add_recorded_publication(archive, channel, stream_id)
        # ... start/stop recording, list recordings, replay, etc.
        close(pub)
    end
end
```

## Notes

- Always `close` publications, subscriptions, counters, images, and archive connections when finished.
