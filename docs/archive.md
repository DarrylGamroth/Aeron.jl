# Aeron Archive usage

This page describes how to use the Aeron Archive client wrapper in Aeron.jl.

## Prerequisites

You need a running Archive service, typically started via `ArchivingMediaDriver` from the Aeron Java distribution.
One common way is to use the `aeron-all` jar from Maven.

### Start an ArchivingMediaDriver

Example (single-process media driver + archive):

```bash
java --add-opens=java.base/jdk.internal.misc=ALL-UNNAMED \
  -Daeron.dir=/tmp/aeron \
  -Daeron.archive.dir=/tmp/archive \
  -Daeron.archive.control.channel=aeron:udp?endpoint=localhost:8010 \
  -Daeron.archive.control.stream.id=1001 \
  -Daeron.archive.control.response.channel=aeron:udp?endpoint=localhost:8011 \
  -Daeron.archive.control.response.stream.id=1002 \
  -Daeron.archive.recording.events.channel=aeron:udp?endpoint=localhost:8012 \
  -Daeron.archive.recording.events.stream.id=1003 \
  -cp aeron-all-<version>.jar \
  io.aeron.archive.ArchivingMediaDriver
```

Make sure `aeron.dir` points at the same directory your Aeron client uses.

## Archive context configuration

Configure the archive context with the same channels and stream IDs used by the archive service.

```julia
using Aeron
const AeronArchive = Aeron.AeronArchive

Aeron.Context() do ctx
    Aeron.aeron_dir!(ctx, "/tmp/aeron")

    Aeron.Client(ctx) do client
        AeronArchive.Context() do archive_ctx
            AeronArchive.aeron_dir!(archive_ctx, "/tmp/aeron")
            AeronArchive.control_request_channel!(archive_ctx, "aeron:udp?endpoint=localhost:8010")
            AeronArchive.control_request_stream_id!(archive_ctx, 1001)
            AeronArchive.control_response_channel!(archive_ctx, "aeron:udp?endpoint=localhost:8011")
            AeronArchive.control_response_stream_id!(archive_ctx, 1002)
            AeronArchive.recording_events_channel!(archive_ctx, "aeron:udp?endpoint=localhost:8012")
            AeronArchive.recording_events_stream_id!(archive_ctx, 1003)

            AeronArchive.client!(archive_ctx, client)

            AeronArchive.connect(archive_ctx) do archive
                println("Archive id: ", AeronArchive.archive_id(archive))
            end
        end
    end
end
```

## Invoker mode (client conductor)

Invoker mode for archive usage is driven by the underlying Aeron client. If you
enable invoker mode, you must call `Aeron.do_work(client)` in your own loop to
drive the conductor, even while using the archive client.

```julia
using Aeron
const AeronArchive = Aeron.AeronArchive

Aeron.Context() do ctx
    Aeron.use_conductor_agent_invoker!(ctx, true)
    Aeron.aeron_dir!(ctx, "/tmp/aeron")

    Aeron.Client(ctx) do client
        AeronArchive.Context() do archive_ctx
            AeronArchive.aeron_dir!(archive_ctx, "/tmp/aeron")
            AeronArchive.client!(archive_ctx, client)

            AeronArchive.connect(archive_ctx) do archive
                while true
                    Aeron.do_work(client)
                    # archive requests or polling go here
                    break
                end
            end
        end
    end
end
```

## Recording and replay

### Start and stop recording a publication

```julia
channel = "aeron:udp?endpoint=localhost:20121"
stream_id = 1001

AeronArchive.connect(archive_ctx) do archive
    pub = AeronArchive.add_recorded_publication(archive, channel, stream_id)
    try
        # Publish messages using the returned publication...
        AeronArchive.stop_recording(archive, pub)
    finally
        close(pub)
    end
end
```

### Record a subscription

```julia
AeronArchive.connect(archive_ctx) do archive
    sub_channel = "aeron:udp?endpoint=localhost:20121"
    sub_stream_id = 1001
    subscription_id = AeronArchive.start_recording(
        archive,
        sub_channel,
        sub_stream_id,
        AeronArchive.SourceLocation.LOCAL,
    )

    # ... send data to the channel ...

    AeronArchive.stop_recording(archive, subscription_id)
end
```

### Replay

```julia
AeronArchive.connect(archive_ctx) do archive
    recording_id = 1
    replay_channel = "aeron:udp?endpoint=localhost:0"
    replay_stream_id = 2001

    session_id = AeronArchive.start_replay(
        archive,
        recording_id,
        replay_channel,
        replay_stream_id,
    )

    # ... create a subscription on replay_channel/replay_stream_id ...

    AeronArchive.stop_replay(archive, session_id)
end
```

## Listing recordings

```julia
AeronArchive.connect(archive_ctx) do archive
    count = AeronArchive.list_recordings((desc, _) -> begin
        println("recording id: ", desc.recording_id)
    end, archive, 0, 10)
    println("listed: ", count)
end
```

### Non-allocating descriptor views

Use view APIs to avoid `String` allocations when listing recordings. Views return
`StringView` fields and are only valid during the callback.

```julia
AeronArchive.connect(archive_ctx) do archive
    AeronArchive.list_recordings_view((desc, _) -> begin
        println("recording: ", desc.recording_id, " ", desc.original_channel)
    end, archive, 0, 10)
end
```

For subscriptions:

```julia
AeronArchive.connect(archive_ctx) do archive
    AeronArchive.list_recording_subscriptions_view((desc, _) -> begin
        println("subscription: ", desc.subscription_id, " ", desc.stripped_channel)
    end, archive, 0, 10, "aeron:ipc", 1001, true)
end
```

Do not retain `RecordingDescriptorView` or `RecordingSubscriptionDescriptorView`
instances beyond the callback. If you need stable values, copy them inside
the callback with `String(...)`.

## Segment maintenance

```julia
AeronArchive.connect(archive_ctx) do archive
    recording_id = 1
    base_pos = AeronArchive.segment_file_base_position(
        AeronArchive.start_position(archive, recording_id),
        AeronArchive.segment_file_length(archive, recording_id),
    )

    AeronArchive.detach_segments(archive, recording_id, base_pos)
    AeronArchive.attach_segments(archive, recording_id)
    AeronArchive.purge_segments(archive, recording_id, base_pos)
    AeronArchive.delete_detached_segments(archive, recording_id)
end
```

## Error handling and cleanup

- Most archive calls throw `ErrorException` when the underlying C API returns a negative result.
- Always `close` publications, subscriptions, and archive connections.
- Archive resources are not automatically cleaned up; use `stop_recording`, `stop_replay`, and `purge_recording` as needed.
