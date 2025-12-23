using Aeron
using Test

include("support.jl")

const AERON_TEST_FILTER = get(ENV, "AERON_TEST_FILTER", "")

function maybe_testset(name::AbstractString, f::Function)
    if isempty(AERON_TEST_FILTER) || occursin(AERON_TEST_FILTER, name)
        @testset "$name" begin
            f()
        end
    end
end

maybe_testset(f::Function, name::AbstractString) = maybe_testset(name, f)

@testset "Aeron client wrapper" begin
    maybe_testset("Version and paths") do
        @test !isempty(Aeron.version())
        @test Aeron.version_major() >= 0
        @test Aeron.version_minor() >= 0
        @test Aeron.version_patch() >= 0
        @test !isempty(Aeron.version_gitsha())
        @test !isempty(Aeron.default_path())
    end

    maybe_testset("Context configuration") do
        Aeron.Context() do ctx
            dir = mktempdir()
            Aeron.aeron_dir!(ctx, dir)
            @test Aeron.aeron_dir(ctx) == dir

            Aeron.driver_timeout_ms!(ctx, 12345)
            @test Aeron.driver_timeout_ms(ctx) == 12345

            Aeron.keepalive_internal_ns!(ctx, 123_456_789)
            @test Aeron.keepalive_internal_ns(ctx) == 123_456_789

            Aeron.resource_linger_duration_ns!(ctx, 987_654_321)
            @test Aeron.resource_linger_duration_ns(ctx) == 987_654_321

            Aeron.idle_sleep_duration_ns!(ctx, 10_000)
            @test Aeron.idle_sleep_duration_ns(ctx) == 10_000

            Aeron.pre_touch_mapped_memory!(ctx, true)
            @test Aeron.pre_touch_mapped_memory(ctx) == true

            Aeron.use_conductor_agent_invoker!(ctx, true)
            @test Aeron.use_conductor_agent_invoker(ctx) == true
        end
    end

    maybe_testset("Client lifecycle") do
        with_embedded_driver() do driver
            Aeron.Context() do context
                Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
                client = Aeron.Client(context)
                try
                    @test Aeron.isopen(client)
                    id1 = Aeron.next_correlation_id(client)
                    id2 = Aeron.next_correlation_id(client)
                    @test id2 > id1
                    @test Aeron.client_id(client) != 0
                finally
                    close(client)
                end
            end
        end
    end

    maybe_testset("Async add operations") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()

                async_sub = Aeron.async_add_subscription(client, channel, stream_id)
                async_pub = Aeron.async_add_publication(client, channel, stream_id)
                async_counter = Aeron.async_add_counter(client, Int32(2001), nothing, "async-counter")

                sub = nothing
                pub = nothing
                counter = nothing
                wait_for(() -> begin
                    if sub === nothing
                        sub = Aeron.poll(async_sub)
                    end
                    if pub === nothing
                        pub = Aeron.poll(async_pub)
                    end
                    if counter === nothing
                        counter = Aeron.poll(async_counter)
                    end
                    sub !== nothing && pub !== nothing && counter !== nothing
                end)

                @test sub !== nothing
                @test pub !== nothing
                @test counter !== nothing

                close(pub)
                close(sub)
                close(counter)
            end
        end
    end

    maybe_testset("Publication and subscription") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("hello aeron"))

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    header_values = Ref{Any}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, header) -> begin
                        received[] = Vector{UInt8}(buffer)
                        header_values[] = Aeron.values(header)
                    end)

                    offer_until_success(pub, payload)
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end)

                    @test received[] == payload
                    vals = header_values[]
                    @test vals.frame.stream_id == stream_id
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Vector offer publication") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    buf1 = Vector{UInt8}(codeunits("hello "))
                    buf2 = Vector{UInt8}(codeunits("vector"))
                    expected = vcat(buf1, buf2)

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received[] = Vector{UInt8}(buffer)
                    end)

                    offer_vec_until_success(pub, [buf1, buf2])
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end)
                    @test received[] == expected
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Publication and subscription properties") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    @test Aeron.channel(pub) == channel
                    @test Aeron.channel(sub) == channel
                    @test Aeron.stream_id(pub) == stream_id
                    @test Aeron.stream_id(sub) == stream_id
                    @test Aeron.registration_id(pub) > 0
                    @test Aeron.registration_id(sub) > 0
                    @test Aeron.original_registration_id(pub) > 0
                    @test Aeron.session_id(pub) != 0
                    @test Aeron.initial_term_id(pub) != 0
                    @test Aeron.max_message_length(pub) > 0
                    @test Aeron.max_payload_length(pub) > 0
                    @test Aeron.position_limit(pub) >= 0
                    @test Aeron.max_possible_position(pub) > 0
                    @test Aeron.channel_status_indicator_id(pub) >= -1
                    @test Aeron.publication_limit_counter_id(pub) >= -1
                    @test Aeron.channel_status_indicator_id(sub) >= -1
                    @test Aeron.channel_status(pub) in (:active, :errored)
                    @test Aeron.channel_status(sub) in (:active, :errored)

                    wait_for(() -> Aeron.image_count(sub) > 0)
                    @test Aeron.image_count(sub) >= 1
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Publication destination management") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                pub_channel = "aeron:udp?control-mode=manual|tags=3001,3002"
                dest1 = "aeron:udp?endpoint=localhost:24326|group=true"
                dest2 = "aeron:udp?endpoint=localhost:24327|group=true"
                stream_id = next_stream_id()

                sub1 = Aeron.add_subscription(client, dest1, stream_id)
                sub2 = Aeron.add_subscription(client, dest2, stream_id)
                pub = Aeron.add_publication(client, pub_channel, stream_id)
                try
                    Aeron.add_destination(pub, dest1)
                    Aeron.add_destination(pub, dest2)
                    await_connected(pub, sub1)
                    await_connected(pub, sub2)
                    @test Aeron.is_connected(sub1)
                    @test Aeron.is_connected(sub2)

                    payload = Vector{UInt8}(codeunits("mds"))
                    handler = Aeron.FragmentHandler((_, _, _) -> nothing)
                    offer_until_success(pub, payload)
                    wait_for(() -> Aeron.poll(sub1, handler, 10) > 0)
                    wait_for(() -> Aeron.poll(sub2, handler, 10) > 0)

                    Aeron.remove_destination(pub, dest1)
                    offer_until_success(pub, payload)
                    wait_for(() -> Aeron.poll(sub2, handler, 10) > 0)
                finally
                    close(pub)
                    close(sub1)
                    close(sub2)
                end
            end
        end
    end

    maybe_testset("Publication destination remove by id") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                pub_channel = "aeron:udp?control-mode=manual|tags=3101,3102"
                dest1 = "aeron:udp?endpoint=localhost:24328|group=true"
                stream_id = next_stream_id()

                sub = Aeron.add_subscription(client, dest1, stream_id)
                pub = Aeron.add_publication(client, pub_channel, stream_id)
                try
                    async_add = Aeron.async_add_destination(pub, dest1)
                    wait_for(() -> Aeron.poll(pub, async_add))
                    dest_id = Aeron.aeron_async_destination_get_registration_id(async_add.async)
                    @test dest_id > 0

                    async_remove = Aeron.async_remove_destination_by_id(pub, dest_id)
                    wait_for(() -> Aeron.poll(pub, async_remove))
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("ExclusivePublication destination remove by id") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                pub_channel = "aeron:udp?control-mode=manual|tags=3201,3202"
                dest1 = "aeron:udp?endpoint=localhost:24329|group=true"
                stream_id = next_stream_id()

                sub = Aeron.add_subscription(client, dest1, stream_id)
                pub = Aeron.add_exclusive_publication(client, pub_channel, stream_id)
                try
                    async_add = Aeron.async_add_destination(pub, dest1)
                    wait_for(() -> Aeron.poll(pub, async_add))
                    dest_id = Aeron.aeron_async_destination_get_registration_id(async_add.async)
                    @test dest_id > 0

                    async_remove = Aeron.async_remove_destination_by_id(pub, dest_id)
                    wait_for(() -> Aeron.poll(pub, async_remove))
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Subscription destination management") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel1 = "aeron:udp?endpoint=localhost:24325"
                channel2 = "aeron:udp?endpoint=localhost:24326"
                sub_channel = "aeron:udp?control-mode=manual"
                stream_id = next_stream_id()

                pub1 = Aeron.add_publication(client, channel1, stream_id)
                pub2 = Aeron.add_publication(client, channel2, stream_id)
                sub = Aeron.add_subscription(client, sub_channel, stream_id)
                try
                    Aeron.add_destination(sub, channel1)
                    Aeron.add_destination(sub, channel2)

                    payload = Vector{UInt8}(codeunits("sub-dest"))
                    handler = Aeron.FragmentHandler((_, _, _) -> nothing)
                    offer_until_success(pub1, payload)
                    wait_for(() -> Aeron.poll(sub, handler, 10) > 0)
                    offer_until_success(pub2, payload)
                    wait_for(() -> Aeron.poll(sub, handler, 10) > 0)

                    Aeron.remove_destination(sub, channel1)
                    offer_until_success(pub2, payload)
                    wait_for(() -> Aeron.poll(sub, handler, 10) > 0)
                finally
                    close(pub1)
                    close(pub2)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Image by session id") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                seen_session = Ref(Int32(0))
                available = Ref(false)
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = image -> begin
                        seen_session[] = Aeron.session_id(image)
                        available[] = true
                        nothing
                    end)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    wait_for(() -> available[])
                    image = Aeron.image_by_session_id(sub, seen_session[])
                    @test image !== nothing
                    @test Aeron.session_id(image) == seen_session[]
                    close(image)
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Image at index do-block") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                available = Ref(false)
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = _ -> begin
                        available[] = true
                        nothing
                    end)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    wait_for(() -> available[])
                    saw = Ref(false)
                    Aeron.image_at_index(sub, 0) do image
                        saw[] = true
                        @test Aeron.session_id(image) == Aeron.session_id(pub)
                    end
                    @test saw[]
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Reserved value supplier") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("reserved"))
                    reserved_value = Int64(7_891_234_567)
                    supplier = Aeron.ReservedValueSupplier((_, _) -> reserved_value)

                    received = Ref{Bool}(false)
                    seen_reserved = Ref{Int64}(0)
                    handler = Aeron.FragmentHandler((_, buffer, header) -> begin
                        received[] = true
                        vals = Aeron.values(header)
                        seen_reserved[] = vals.frame.reserved_value
                    end)

                    offer_with_supplier_until_success(pub, payload, supplier)
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[]
                    end)

                    @test seen_reserved[] == reserved_value
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("BufferClaim commit and abort") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("claim payload"))

                    claim = nothing
                    wait_for(() -> begin
                        claim, position = Aeron.try_claim(pub, length(payload))
                        position > 0
                    end)

                    claim_buffer = Aeron.buffer(claim)
                    claim_buffer[1:length(payload)] .= payload
                    Aeron.commit(claim)

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received[] = Vector{UInt8}(buffer)
                    end)

                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end)
                    @test received[] == payload

                    abort_payload = Vector{UInt8}(codeunits("abort payload"))
                    wait_for(() -> begin
                        claim, position = Aeron.try_claim(pub, length(abort_payload))
                        position > 0
                    end)
                    Aeron.abort(claim)

                    received_abort = Ref{Bool}(false)
                    abort_handler = Aeron.FragmentHandler((_, _, _) -> begin
                        received_abort[] = true
                    end)

                    received_in_time = poll_for(() -> begin
                        Aeron.poll(sub, abort_handler, 10) > 0 && received_abort[]
                    end; timeout=0.5)

                    @test !received_in_time
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("ExclusivePublication basic flow") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_exclusive_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("exclusive hello"))

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received[] = Vector{UInt8}(buffer)
                    end)

                    offer_until_success(pub, payload)
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end)

                    @test received[] == payload
                    @test Aeron.channel(pub) == channel
                    @test Aeron.stream_id(pub) == stream_id
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("ExclusivePublication reserved value and claim") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_exclusive_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("exclusive reserved"))
                    reserved_value = Int64(99)
                    supplier = Aeron.ReservedValueSupplier((_, _) -> reserved_value)

                    received = Ref{Bool}(false)
                    seen_reserved = Ref{Int64}(0)
                    handler = Aeron.FragmentHandler((_, _, header) -> begin
                        received[] = true
                        vals = Aeron.values(header)
                        seen_reserved[] = vals.frame.reserved_value
                    end)

                    offer_with_supplier_until_success(pub, payload, supplier)
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[]
                    end)
                    @test seen_reserved[] == reserved_value

                    claim_payload = Vector{UInt8}(codeunits("exclusive claim"))
                    claim = nothing
                    wait_for(() -> begin
                        claim, position = Aeron.try_claim(pub, length(claim_payload))
                        position > 0
                    end)
                    claim_buffer = Aeron.buffer(claim)
                    claim_buffer[1:length(claim_payload)] .= claim_payload
                    Aeron.commit(claim)

                    received_claim = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    claim_handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received_claim[] = Vector{UInt8}(buffer)
                    end)
                    wait_for(() -> begin
                        Aeron.poll(sub, claim_handler, 10) > 0 && received_claim[] !== nothing
                    end)
                    @test received_claim[] == claim_payload
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("ExclusivePublication revoke") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                image_ref = Ref{Any}(nothing)
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = image -> begin
                        image_ref[] = image
                        nothing
                    end)
                pub = Aeron.add_exclusive_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    wait_for(() -> image_ref[] !== nothing)
                    Aeron.revoke(pub)
                    wait_for(() -> Aeron.is_publication_revoked(image_ref[]))
                    @test Aeron.is_publication_revoked(image_ref[])
                finally
                    if Aeron.isopen(pub)
                        close(pub)
                    end
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Vector offer exclusive publication") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_exclusive_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    buf1 = Vector{UInt8}(codeunits("exclusive "))
                    buf2 = Vector{UInt8}(codeunits("vector"))
                    expected = vcat(buf1, buf2)

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received[] = Vector{UInt8}(buffer)
                    end)

                    offer_vec_until_success(pub, [buf1, buf2])
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end)
                    @test received[] == expected
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Context callbacks") do
        with_embedded_driver() do driver
            Aeron.Context() do context
                Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
                Aeron.use_conductor_agent_invoker!(context, true)
                new_pub = Ref(0)
                new_sub = Ref(0)
                new_exclusive = Ref(0)
                available_counter = Ref(0)
                unavailable_counter = Ref(0)
                closed = Ref(0)

                Aeron.on_new_publication!((_, _, _, _, _) -> begin
                    new_pub[] += 1
                    nothing
                end, context)
                Aeron.on_new_subscription!((_, _, _, _, _) -> begin
                    new_sub[] += 1
                    nothing
                end, context)
                Aeron.on_new_exclusive_publication!((_, _, _, _, _) -> begin
                    new_exclusive[] += 1
                    nothing
                end, context)
                Aeron.on_available_counter!((_, _, _) -> begin
                    available_counter[] += 1
                    nothing
                end, context)
                Aeron.on_unavailable_counter!((_, _, _) -> begin
                    unavailable_counter[] += 1
                    nothing
                end, context)
                Aeron.on_close_client!((_) -> begin
                    closed[] += 1
                    nothing
                end, context)

                client = Aeron.Client(context)
                try
                    channel = ipc_channel()
                    stream_id = next_stream_id()
                    async_sub = Aeron.async_add_subscription(client, channel, stream_id)
                    async_pub = Aeron.async_add_publication(client, channel, stream_id)
                    async_ex_pub = Aeron.async_add_exclusive_publication(client, channel, stream_id)
                    async_counter = Aeron.async_add_counter(client, Int32(2010), nothing, "callback-counter")

                    sub = nothing
                    pub = nothing
                    ex_pub = nothing
                    counter = nothing

                    wait_for(() -> begin
                        Aeron.do_work(client)
                        if sub === nothing
                            sub = Aeron.poll(async_sub)
                        end
                        if pub === nothing
                            pub = Aeron.poll(async_pub)
                        end
                        if ex_pub === nothing
                            ex_pub = Aeron.poll(async_ex_pub)
                        end
                        if counter === nothing
                            counter = Aeron.poll(async_counter)
                        end
                        sub !== nothing && pub !== nothing && ex_pub !== nothing && counter !== nothing
                    end)

                    wait_for(() -> begin
                        Aeron.do_work(client)
                        new_pub[] > 0 && new_sub[] > 0 && new_exclusive[] > 0 && available_counter[] > 0
                    end)

                    close(counter)
                    wait_for(() -> begin
                        Aeron.do_work(client)
                        unavailable_counter[] > 0
                    end)
                    close(pub)
                    close(ex_pub)
                    close(sub)
                finally
                    close(client)
                end
                wait_for(() -> closed[] > 0)
                @test new_pub[] > 0
                @test new_sub[] > 0
                @test new_exclusive[] > 0
                @test available_counter[] > 0
                @test unavailable_counter[] > 0
                @test closed[] > 0
            end
        end
    end

    maybe_testset("Context error callback") do
        with_embedded_driver() do driver
            Aeron.Context() do context
                Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
                error_seen = Ref(false)
                error_cb = (_, _, _) -> begin
                    error_seen[] = true
                    nothing
                end
                Aeron.on_error!(error_cb, context)

                Aeron.Client(context) do _
                    nothing
                end
                error_cb(nothing, 0, "test")
                @test error_seen[]
            end
        end
    end

    maybe_testset("FragmentAssembler reassembles fragments") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    max_payload = Int(Aeron.max_payload_length(pub))
                    max_message = Int(Aeron.max_message_length(pub))
                    @test max_message > max_payload
                    len = min(max_message - 64, max_payload * 2 + 5)
                    if len <= max_payload
                        len = max_payload + 1
                    end
                    if len > max_message
                        len = max_message
                    end
                    payload = Vector{UInt8}(undef, len)
                    for i in eachindex(payload)
                        payload[i] = UInt8(i % 255)
                    end

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler((_, buffer, _) -> begin
                        received[] = Vector{UInt8}(buffer)
                    end)
                    assembler = Aeron.FragmentAssembler(handler)

                    offer_until_success(pub, payload)
                    wait_for(() -> begin
                        Aeron.poll(sub, assembler, 10) > 0 && received[] !== nothing
                    end)

                    @test received[] == payload
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Controlled fragment handlers") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    max_payload = Int(Aeron.max_payload_length(pub))
                    max_message = Int(Aeron.max_message_length(pub))
                    @test max_message > max_payload
                    len = min(max_message - 64, max_payload * 2 + 7)
                    if len <= max_payload
                        len = max_payload + 1
                    end
                    if len > max_message
                        len = max_message
                    end
                    payload = Vector{UInt8}(undef, len)
                    for i in eachindex(payload)
                        payload[i] = UInt8(255 - (i % 255))
                    end

                    count = Ref(0)
                    handler = Aeron.ControlledFragmentHandler((_, _, _) -> begin
                        count[] += 1
                        if count[] == 1
                            return Aeron.ControlledAction.BREAK
                        end
                        return Aeron.ControlledAction.CONTINUE
                    end)

                    offer_until_success(pub, payload)
                    Aeron.poll(sub, handler, 10)
                    @test count[] == 1

                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 10) > 0 && count[] > 1
                    end)

                    assembled = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    inner_handler = Aeron.ControlledFragmentHandler((_, buffer, _) -> begin
                        assembled[] = Vector{UInt8}(buffer)
                        return Aeron.ControlledAction.COMMIT
                    end)
                    assembler = Aeron.ControlledFragmentAssembler(inner_handler)

                    offer_until_success(pub, payload)
                    wait_for(() -> begin
                        Aeron.poll(sub, assembler, 10) > 0 && assembled[] !== nothing
                    end)
                    @test assembled[] == payload
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Block handler poll") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()
                sub = Aeron.add_subscription(client, channel, stream_id)
                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    payload = Vector{UInt8}(codeunits("block"))
                    offer_until_success(pub, payload)

                    seen = Ref(false)
                    handler = Aeron.BlockHandler((_, buffer, session_id, term_id) -> begin
                        seen[] = length(buffer) > 0
                    end)
                    wait_for(() -> begin
                        Aeron.poll(sub, handler, 1024) > 0 && seen[]
                    end)
                    @test seen[]
                finally
                    close(pub)
                    close(sub)
                end
            end
        end
    end

    maybe_testset("Counters and CountersReader") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                type_id = Int32(1001)
                label = "test-counter"
                key = Vector{UInt8}(collect(UInt8, 1:8))
                counter = Aeron.add_counter(client, type_id, key, label)
                try
                    reader = Aeron.CountersReader(client)
                    counter_id = Aeron.counter_id(counter)
                    reg_id = Aeron.registration_id(counter)

                    found_id = Ref{Union{Nothing, Int32}}(nothing)
                    wait_for(() -> begin
                        found_id[] = Aeron.find_counter_by_type_id_and_registration_id(reader, type_id, reg_id)
                        found_id[] !== nothing
                    end)

                    @test Aeron.counter_value(reader, counter_id) == 0
                    @test Aeron.counter_registration_id(reader, counter_id) == reg_id
                    @test Aeron.counter_type_id(reader, counter_id) == type_id
                    @test Aeron.counter_label(reader, counter_id) == label
                    @test Aeron.counter_owner_id(reader, counter_id) >= 0
                    @test Aeron.counter_reference_id(reader, counter_id) >= 0
                    @test Aeron.counter_state(reader, counter_id) == Aeron.CounterState.RECORD_ALLOCATED
                    @test Aeron.free_for_reuse_deadline_ms(reader, counter_id) >= 0
                    @test Aeron.max_counter_id(reader) >= counter_id

                    counter[] = 10
                    @test counter[] == 10
                    @test Aeron.increment!(counter) == 10
                    @test counter[] == 11
                    @test Aeron.decrement!(counter, 2) == 11
                    @test counter[] == 9
                    @test Aeron.add!(counter, 5) == 9
                    @test counter[] == 14
                    @test Aeron.get_and_set!(counter, 1) == 14
                    @test counter[] == 1
                    @test Aeron.get_and_add!(counter, 3) == 1
                    @test counter[] == 4
                    @test Aeron.compare_and_set!(counter, 4, 8) == true
                    @test counter[] == 8
                    @test Aeron.compare_and_set!(counter, 4, 9) == false

                    seen = Ref(false)
                    Aeron.counter_foreach((value, id, type_id_seen, key_seen, label_seen, _) -> begin
                        if id == counter_id
                            seen[] = true
                            @test type_id_seen == type_id
                            @test label_seen == label
                            @test length(key_seen) >= length(key)
                            @test key_seen[1:length(key)] == key
                        end
                    end, reader)
                    @test seen[]
                finally
                    close(counter)
                end
            end
        end
    end

    maybe_testset("Exception mapping") do
        @test_throws ArgumentError Aeron.map_to_exception_and_throw(Libc.EINVAL, "invalid")
        @test_throws Aeron.IllegalStateException Aeron.map_to_exception_and_throw(Libc.EPERM, "state")
        @test_throws Aeron.IOException Aeron.map_to_exception_and_throw(Libc.EIO, "io")
        @test_throws Aeron.DriverTimeoutException Aeron.map_to_exception_and_throw(Aeron.AERON_CLIENT_ERROR_DRIVER_TIMEOUT, "driver")
        @test_throws Aeron.ClientTimeoutException Aeron.map_to_exception_and_throw(Aeron.AERON_CLIENT_ERROR_CLIENT_TIMEOUT, "client")
        @test_throws Aeron.ConductorServiceTimeoutException Aeron.map_to_exception_and_throw(
            Aeron.AERON_CLIENT_ERROR_CONDUCTOR_SERVICE_TIMEOUT, "conductor")
    end
end
