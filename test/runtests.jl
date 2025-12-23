using Aeron
using StringViews
const AeronArchive = Aeron.AeronArchive
using Test

include("support.jl")
include("support_archive.jl")

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

                async_sub_view = Aeron.async_add_subscription_view(client, channel, stream_id)
                sub = nothing
                pub = nothing
                counter = nothing
                sub_view = nothing
                wait_for() do
                    if sub === nothing
                        sub = Aeron.poll(async_sub)
                    end
                    if pub === nothing
                        pub = Aeron.poll(async_pub)
                    end
                    if counter === nothing
                        counter = Aeron.poll(async_counter)
                    end
                    if sub_view === nothing
                        sub_view = Aeron.poll(async_sub_view)
                    end
                    sub !== nothing && pub !== nothing && counter !== nothing && sub_view !== nothing
                end

                @test sub !== nothing
                @test pub !== nothing
                @test counter !== nothing
                @test sub_view !== nothing

                close(pub)
                close(sub)
                close(counter)
                close(sub_view)
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
                    handler = Aeron.FragmentHandler() do _, buffer, header
                        received[] = Vector{UInt8}(buffer)
                        header_values[] = Aeron.values(header)
                    end

                    offer_until_success(pub, payload)
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end

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

    maybe_testset("Subscription view callbacks") do
        with_embedded_driver() do driver
            with_client(; driver=driver) do client
                channel = ipc_channel()
                stream_id = next_stream_id()

                available_view = Ref{Any}(nothing)
                alloc_bytes = Ref{Int}(0)
                unavailable_called = Ref(false)

                sub = Aeron.add_subscription_view(client, channel, stream_id;
                    on_available_image = imgv -> begin
                        available_view[] = imgv
                        alloc_bytes[] = @allocated Aeron.source_identity(imgv)
                    end,
                    on_unavailable_image = _ -> (unavailable_called[] = true))

                GC.gc()

                pub = Aeron.add_publication(client, channel, stream_id)
                try
                    await_connected(pub, sub)
                    wait_for(() -> available_view[] !== nothing)
                    imgv = available_view[]
                    @test imgv isa Aeron.ImageView
                    @test Aeron.source_identity(imgv) isa StringView
                    @test !isempty(String(Aeron.source_identity(imgv)))
                    @test alloc_bytes[] <= 256
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
                    handler = Aeron.FragmentHandler() do _, buffer, _
                        received[] = Vector{UInt8}(buffer)
                    end

                    offer_vec_until_success(pub, [buf1, buf2])
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end
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
                function on_available_image(image)
                    seen_session[] = Aeron.session_id(image)
                    available[] = true
                    nothing
                end
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = on_available_image)
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
                function on_available_image(_)
                    available[] = true
                    nothing
                end
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = on_available_image)
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
                    handler = Aeron.FragmentHandler() do _, buffer, header
                        received[] = true
                        vals = Aeron.values(header)
                        seen_reserved[] = vals.frame.reserved_value
                    end

                    offer_with_supplier_until_success(pub, payload, supplier)
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[]
                    end

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
                    wait_for() do
                        claim, position = Aeron.try_claim(pub, length(payload))
                        position > 0
                    end

                    claim_buffer = Aeron.buffer(claim)
                    claim_buffer[1:length(payload)] .= payload
                    Aeron.commit(claim)

                    received = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    handler = Aeron.FragmentHandler() do _, buffer, _
                        received[] = Vector{UInt8}(buffer)
                    end

                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end
                    @test received[] == payload

                    abort_payload = Vector{UInt8}(codeunits("abort payload"))
                    wait_for() do
                        claim, position = Aeron.try_claim(pub, length(abort_payload))
                        position > 0
                    end
                    Aeron.abort(claim)

                    received_abort = Ref{Bool}(false)
                    abort_handler = Aeron.FragmentHandler() do _, _, _
                        received_abort[] = true
                    end

                    received_in_time = poll_for(; timeout=0.5) do
                        Aeron.poll(sub, abort_handler, 10) > 0 && received_abort[]
                    end

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
                    handler = Aeron.FragmentHandler() do _, buffer, _
                        received[] = Vector{UInt8}(buffer)
                    end

                    offer_until_success(pub, payload)
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end

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
                    handler = Aeron.FragmentHandler() do _, _, header
                        received[] = true
                        vals = Aeron.values(header)
                        seen_reserved[] = vals.frame.reserved_value
                    end

                    offer_with_supplier_until_success(pub, payload, supplier)
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[]
                    end
                    @test seen_reserved[] == reserved_value

                    claim_payload = Vector{UInt8}(codeunits("exclusive claim"))
                    claim = nothing
                    wait_for() do
                        claim, position = Aeron.try_claim(pub, length(claim_payload))
                        position > 0
                    end
                    claim_buffer = Aeron.buffer(claim)
                    claim_buffer[1:length(claim_payload)] .= claim_payload
                    Aeron.commit(claim)

                    received_claim = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    claim_handler = Aeron.FragmentHandler() do _, buffer, _
                        received_claim[] = Vector{UInt8}(buffer)
                    end
                    wait_for() do
                        Aeron.poll(sub, claim_handler, 10) > 0 && received_claim[] !== nothing
                    end
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
                function on_available_image(image)
                    image_ref[] = image
                    nothing
                end
                sub = Aeron.add_subscription(client, channel, stream_id;
                    on_available_image = on_available_image)
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
                    handler = Aeron.FragmentHandler() do _, buffer, _
                        received[] = Vector{UInt8}(buffer)
                    end

                    offer_vec_until_success(pub, [buf1, buf2])
                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && received[] !== nothing
                    end
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

                function on_new_publication_handler(_, _, _, _, _)
                    new_pub[] += 1
                    nothing
                end
                function on_new_subscription_handler(_, _, _, _, _)
                    new_sub[] += 1
                    nothing
                end
                function on_new_exclusive_publication_handler(_, _, _, _, _)
                    new_exclusive[] += 1
                    nothing
                end
                function on_available_counter_handler(_, _, _)
                    available_counter[] += 1
                    nothing
                end
                function on_unavailable_counter_handler(_, _, _)
                    unavailable_counter[] += 1
                    nothing
                end
                function on_close_client_handler(_)
                    closed[] += 1
                    nothing
                end

                Aeron.on_new_publication!(on_new_publication_handler, context)
                Aeron.on_new_subscription!(on_new_subscription_handler, context)
                Aeron.on_new_exclusive_publication!(on_new_exclusive_publication_handler, context)
                Aeron.on_available_counter!(on_available_counter_handler, context)
                Aeron.on_unavailable_counter!(on_unavailable_counter_handler, context)
                Aeron.on_close_client!(on_close_client_handler, context)

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

                    wait_for() do
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
                    end

                    wait_for() do
                        Aeron.do_work(client)
                        new_pub[] > 0 && new_sub[] > 0 && new_exclusive[] > 0 && available_counter[] > 0
                    end

                    close(counter)
                    wait_for() do
                        Aeron.do_work(client)
                        unavailable_counter[] > 0
                    end
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

    maybe_testset("CnC monitoring") do
        with_embedded_driver() do driver
            cnc = Aeron.CnC(; base_path=Aeron.MediaDriver.aeron_dir(driver))
            try
                @test Aeron.cnc_version(cnc) >= 0
                @test Aeron.file_page_size(cnc) > 0
                @test Aeron.client_liveness_timeout(cnc) >= 0
                @test Aeron.start_timestamp(cnc) >= 0
                @test Aeron.pid(cnc) >= 0

                counters = Aeron.counters_reader(cnc)
                @test Aeron.max_counter_id(counters) >= 0

                error_entries = Ref(0)
                Aeron.error_log_read(cnc) do _, _, _, _, _
                    error_entries[] += 1
                end
                @test error_entries[] >= 0

                loss_entries = Ref(0)
                Aeron.loss_report_read(cnc) do _, _, _, _, _, _, _, _, _
                    loss_entries[] += 1
                end
                @test loss_entries[] >= 0
            finally
                close(cnc)
            end
        end
    end

    maybe_testset("Context error callback") do
        with_embedded_driver() do driver
            Aeron.Context() do context
                Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
                error_seen = Ref(false)
                function error_cb(_, _, _)
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
                    handler = Aeron.FragmentHandler() do _, buffer, _
                        received[] = Vector{UInt8}(buffer)
                    end
                    assembler = Aeron.FragmentAssembler(handler)

                    offer_until_success(pub, payload)
                    wait_for() do
                        Aeron.poll(sub, assembler, 10) > 0 && received[] !== nothing
                    end

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
                    handler = Aeron.ControlledFragmentHandler() do _, _, _
                        count[] += 1
                        if count[] == 1
                            return Aeron.ControlledAction.BREAK
                        end
                        return Aeron.ControlledAction.CONTINUE
                    end

                    offer_until_success(pub, payload)
                    Aeron.poll(sub, handler, 10)
                    @test count[] == 1

                    wait_for() do
                        Aeron.poll(sub, handler, 10) > 0 && count[] > 1
                    end

                    assembled = Ref{Union{Nothing, Vector{UInt8}}}(nothing)
                    inner_handler = Aeron.ControlledFragmentHandler() do _, buffer, _
                        assembled[] = Vector{UInt8}(buffer)
                        return Aeron.ControlledAction.COMMIT
                    end
                    assembler = Aeron.ControlledFragmentAssembler(inner_handler)

                    offer_until_success(pub, payload)
                    wait_for() do
                        Aeron.poll(sub, assembler, 10) > 0 && assembled[] !== nothing
                    end
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
                    handler = Aeron.BlockHandler() do _, buffer, session_id, term_id
                        seen[] = length(buffer) > 0
                    end
                    wait_for() do
                        Aeron.poll(sub, handler, 1024) > 0 && seen[]
                    end
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
                    wait_for() do
                        found_id[] = Aeron.find_counter_by_type_id_and_registration_id(reader, type_id, reg_id)
                        found_id[] !== nothing
                    end

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

    maybe_testset("Archive context configuration") do
        AeronArchive.Context() do ctx
            dir = mktempdir()
            AeronArchive.aeron_dir!(ctx, dir)
            @test AeronArchive.aeron_dir(ctx) == dir

            AeronArchive.control_request_channel!(ctx, "aeron:udp?endpoint=localhost:8010")
            AeronArchive.control_response_channel!(ctx, "aeron:udp?endpoint=localhost:8011")
            AeronArchive.recording_events_channel!(ctx, "aeron:udp?endpoint=localhost:8012")
            AeronArchive.control_request_stream_id!(ctx, 1001)
            AeronArchive.control_response_stream_id!(ctx, 1002)
            AeronArchive.recording_events_stream_id!(ctx, 1003)
            AeronArchive.message_timeout_ns!(ctx, 5_000_000)
            AeronArchive.control_term_buffer_length!(ctx, 64 * 1024)
            AeronArchive.control_mtu_length!(ctx, Int32(1408))
            AeronArchive.control_term_buffer_sparse!(ctx, true)

            @test AeronArchive.control_request_channel(ctx) == "aeron:udp?endpoint=localhost:8010"
            @test AeronArchive.control_response_channel(ctx) == "aeron:udp?endpoint=localhost:8011"
            @test AeronArchive.recording_events_channel(ctx) == "aeron:udp?endpoint=localhost:8012"
            @test AeronArchive.control_request_stream_id(ctx) == 1001
            @test AeronArchive.control_response_stream_id(ctx) == 1002
            @test AeronArchive.recording_events_stream_id(ctx) == 1003
            @test AeronArchive.message_timeout_ns(ctx) == 5_000_000
            @test AeronArchive.control_term_buffer_length(ctx) == 64 * 1024
            @test AeronArchive.control_mtu_length(ctx) == 1408
            @test AeronArchive.control_term_buffer_sparse(ctx) == true
        end
    end

    maybe_testset("Archive callbacks and params") do
        AeronArchive.Context() do ctx
            supplier = AeronArchive.CredentialsSupplier(
                encoded_credentials = _ -> "user",
                on_chalenge = (_, _) -> "reply",
                clientd = nothing
            )
            AeronArchive.credentials_supplier!(ctx, supplier)
            @test ctx.credentials_supplier === supplier

            error_seen = Ref(false)
            function archive_error_handler(_, _, _)
                error_seen[] = true
                nothing
            end
            AeronArchive.error_handler!(archive_error_handler, ctx)
            msg = "oops"
            GC.@preserve msg begin
                AeronArchive.error_handler_wrapper((archive_error_handler, nothing), 1, Base.unsafe_convert(Cstring, msg))
            end
            @test error_seen[]

            signal_seen = Ref(false)
            function recording_signal_consumer(descriptor, _)
                signal_seen[] = descriptor.recording_id == 7
                nothing
            end
            AeronArchive.recording_signal_consumer!(recording_signal_consumer, ctx)
            signal = AeronArchive.aeron_archive_recording_signal_t(1, 7, 2, 3, 4)
            signal_ref = Ref(signal)
            GC.@preserve signal_ref begin
                AeronArchive.recording_signal_consumer_wrapper(Base.unsafe_convert(Ptr{AeronArchive.aeron_archive_recording_signal_t}, signal_ref),
                    (recording_signal_consumer, nothing))
            end
            @test signal_seen[]

            replay_params = AeronArchive.ReplayParams(
                bounding_limit_counter_id = 3,
                file_io_max_length = 4,
                position = 5,
                length = 6,
                replay_token = 7,
                subscription_registration_id = 8
            )
            cparams = convert(AeronArchive.aeron_archive_replay_params_t, replay_params)
            @test cparams.bounding_limit_counter_id == 3
            @test cparams.file_io_max_length == 4
            @test cparams.position == 5
            @test cparams.length == 6
            @test cparams.replay_token == 7
            @test cparams.subscription_registration_id == 8
            @test convert(AeronArchive.ReplayParams, cparams) == replay_params

            repl_params = AeronArchive.ReplicationParams(
                stop_position = 10,
                dst_recording_id = 11,
                live_destination = "live",
                replication_channel = "repl",
                src_response_channel = "resp",
                channel_tag_id = 12,
                subscription_tag_id = 13,
                file_io_max_length = 14,
                replication_session_id = 15,
                encoded_credentials = nothing
            )
            GC.@preserve repl_params begin
                repl_c = convert(AeronArchive.aeron_archive_replication_params_t, repl_params)
                @test repl_c.stop_position == 10
                @test repl_c.dst_recording_id == 11
                @test unsafe_string(repl_c.live_destination) == "live"
                @test unsafe_string(repl_c.replication_channel) == "repl"
                @test unsafe_string(repl_c.src_response_channel) == "resp"
                @test repl_c.channel_tag_id == 12
                @test repl_c.subscription_tag_id == 13
                @test repl_c.file_io_max_length == 14
                @test repl_c.replication_session_id == 15
            end
        end
    end

    maybe_testset("Archive integration") do
        if !archive_integration_enabled()
            @test true
            return
        end

        jar = archive_jar_path()
        @test jar !== nothing

        with_archiving_media_driver() do cfg
            Aeron.Context() do client_ctx
                Aeron.aeron_dir!(client_ctx, cfg.aeron_dir)
                Aeron.Client(client_ctx) do client
                    AeronArchive.Context() do archive_ctx
                        signals = Ref(Int32[])
                        AeronArchive.aeron_dir!(archive_ctx, cfg.aeron_dir)
                        AeronArchive.control_request_channel!(archive_ctx, cfg.control_channel)
                        AeronArchive.control_request_stream_id!(archive_ctx, cfg.control_stream_id)
                        AeronArchive.control_response_channel!(archive_ctx, cfg.response_channel)
                        AeronArchive.control_response_stream_id!(archive_ctx, cfg.response_stream_id)
                        AeronArchive.recording_events_channel!(archive_ctx, cfg.events_channel)
                        AeronArchive.recording_events_stream_id!(archive_ctx, cfg.events_stream_id)
                        AeronArchive.recording_signal_consumer!(archive_ctx) do desc, _
                            push!(signals[], desc.recording_signal_code)
                        end
                        AeronArchive.client!(archive_ctx, client)

                        AeronArchive.connect(archive_ctx) do archive
                            @test AeronArchive.archive_id(archive) != 0
                            @test AeronArchive.control_session_id(archive) != 0

                            channel = "aeron:ipc"
                            stream_id = next_stream_id()
                            pub = AeronArchive.add_recorded_publication(archive, channel, stream_id)
                            conn_sub = Aeron.add_subscription(client, channel, stream_id)
                            wait_for(() -> Aeron.is_connected(pub) && Aeron.is_connected(conn_sub); timeout=10.0, sleep_s=0.05)
                            session_id = Aeron.session_id(pub)
                            offer_until_success(pub, Vector{UInt8}(codeunits("archive-1")))
                            offer_until_success(pub, Vector{UInt8}(codeunits("archive-2")))
                            bulk_payload = Vector{UInt8}(undef, 4096)
                            for _ in 1:20
                                wait_for(() -> Aeron.offer(pub, bulk_payload) > 0; timeout=10.0, sleep_s=0.0)
                            end
                            AeronArchive.stop_recording(archive, pub)
                            close(pub)
                            close(conn_sub)
                            recording_id = Ref(Int64(-1))
                            wait_for(; timeout=30.0, sleep_s=0.05) do
                                count = AeronArchive.list_recordings((desc, _) -> begin
                                    if desc.stream_id == stream_id && occursin(channel, desc.original_channel)
                                        recording_id[] = desc.recording_id
                                    end
                                    nothing
                                end, archive, 0, 100)
                                count > 0 && recording_id[] >= 0
                            end
                            counters = AeronArchive.CountersReader(archive)
                            counter_id = AeronArchive.find_counter_by_recording_id(counters, recording_id[])
                            if counter_id !== nothing
                                @test AeronArchive.source_identity(counters, counter_id) isa String
                                active = AeronArchive.is_active(counters, counter_id, recording_id[])
                                @test active == true || active == false
                            end

                            seen = Ref(false)
                            desc_ref = Ref{Union{Nothing,AeronArchive.RecordingDescriptor}}(nothing)
                            count = AeronArchive.list_recording((desc, _) -> begin
                                seen[] = desc.recording_id == recording_id[]
                                if desc.recording_id == recording_id[]
                                    desc_ref[] = desc
                                end
                                nothing
                            end, archive, recording_id[])
                            @test count > 0
                            @test seen[]

                            paged = Ref(false)
                            page_count = AeronArchive.list_recordings((desc, _) -> begin
                                paged[] = desc.recording_id == recording_id[]
                                nothing
                            end, archive, 0, 1)
                            @test page_count > 0
                            @test paged[]

                            list_seen = Ref(false)
                            list_count = AeronArchive.list_recordings_for_uri((desc, _) -> begin
                                list_seen[] = desc.recording_id == recording_id[]
                                nothing
                            end, archive, 0, 10, channel, stream_id)
                            @test list_count >= 0
                            if list_count > 0
                                @test list_seen[]
                            end

                            view_seen = Ref(false)
                            view_alloc = Ref(0)
                            view_count = AeronArchive.list_recordings_view((desc, _) -> begin
                                view_seen[] = desc.recording_id == recording_id[]
                                view_alloc[] = @allocated desc.original_channel
                                @test desc.original_channel isa StringView
                                @test desc.stripped_channel isa StringView
                                @test desc.source_identity isa StringView
                                nothing
                            end, archive, 0, 10)
                            @test view_count >= 0
                            if view_count > 0
                                @test view_seen[]
                                @test view_alloc[] <= 256
                            end

                            sub_channel = "aeron:ipc"
                            sub_stream_id = next_stream_id()
                            subscription_id = AeronArchive.start_recording(archive, sub_channel, sub_stream_id, AeronArchive.SourceLocation.LOCAL)
                            @test subscription_id > 0
                            sub_pub = Aeron.add_publication(client, sub_channel, sub_stream_id)
                            offer_until_success(sub_pub, Vector{UInt8}(codeunits("sub-recording")))

                            sub_seen = Ref(false)
                            sub_count = AeronArchive.list_recording_subscriptions((desc, _) -> begin
                                sub_seen[] = desc.subscription_id == subscription_id
                                nothing
                            end, archive, 0, 10, sub_channel, sub_stream_id, true)
                            @test sub_count > 0
                            @test sub_seen[]

                            sub_view_seen = Ref(false)
                            sub_view_alloc = Ref(0)
                            sub_view_count = AeronArchive.list_recording_subscriptions_view((desc, _) -> begin
                                sub_view_seen[] = desc.subscription_id == subscription_id
                                sub_view_alloc[] = @allocated desc.stripped_channel
                                @test desc.stripped_channel isa StringView
                                nothing
                            end, archive, 0, 10, sub_channel, sub_stream_id, true)
                            @test sub_view_count > 0
                            @test sub_view_seen[]
                            @test sub_view_alloc[] <= 256

                            AeronArchive.stop_recording(archive, subscription_id)
                            close(sub_pub)

                            @test AeronArchive.start_position(archive, recording_id[]) >= 0
                            @test AeronArchive.stop_position(archive, recording_id[]) >= AeronArchive.start_position(archive, recording_id[])

                            old_stop = AeronArchive.stop_position(archive, recording_id[])
                            extend_id = AeronArchive.extend_recording(archive, recording_id[], channel, stream_id, AeronArchive.SourceLocation.LOCAL)
                            @test extend_id > 0
                            extend_pub = Aeron.add_publication(client, channel, stream_id)
                            offer_until_success(extend_pub, Vector{UInt8}(codeunits("archive-3")))
                            AeronArchive.stop_recording(archive, extend_id)
                            close(extend_pub)
                            wait_for(() -> AeronArchive.stop_position(archive, recording_id[]) > old_stop; timeout=10.0, sleep_s=0.05)

                            replay_channel = "aeron:ipc"
                            replay_stream_id = next_stream_id()
                            replay_sub = Aeron.add_subscription(client, replay_channel, replay_stream_id)
                            replay_session_id = AeronArchive.start_replay(archive, recording_id[], replay_channel, replay_stream_id)

                            received = Ref{Vector{String}}(String[])
                            handler = Aeron.FragmentHandler() do _, buffer, _
                                push!(received[], String(buffer))
                            end

                            wait_for(; timeout=10.0, sleep_s=0.05) do
                                Aeron.poll(replay_sub, handler, 10)
                                length(received[]) >= 2
                            end

                            @test "archive-1" in received[]
                            @test "archive-2" in received[]
                            AeronArchive.stop_all_replays(archive, recording_id[])
                            close(replay_sub)

                            replay_channel2 = "aeron:ipc"
                            replay_stream_id2 = next_stream_id()
                            start_pos = AeronArchive.start_position(archive, recording_id[])
                            stop_pos = AeronArchive.stop_position(archive, recording_id[])
                            replay_sub2 = AeronArchive.replay(archive, recording_id[], replay_channel2, replay_stream_id2;
                                position=start_pos, length=stop_pos - start_pos)
                            received2 = Ref{Vector{String}}(String[])
                            handler2 = Aeron.FragmentHandler() do _, buffer, _
                                push!(received2[], String(buffer))
                            end
                            wait_for(; timeout=10.0, sleep_s=0.05) do
                                Aeron.poll(replay_sub2, handler2, 10)
                                length(received2[]) >= 2
                            end
                            @test "archive-1" in received2[]
                            @test "archive-2" in received2[]
                            AeronArchive.stop_all_replays(archive, recording_id[])
                            close(replay_sub2)

                            replay_channel3 = "aeron:ipc"
                            replay_stream_id3 = next_stream_id()
                            replay_sub3 = Aeron.add_subscription(client, replay_channel3, replay_stream_id3)
                            replay_id = AeronArchive.start_replay(archive, recording_id[], replay_channel3, replay_stream_id3;
                                position=start_pos, length=stop_pos - start_pos)
                            received3 = Ref{Vector{String}}(String[])
                            handler3 = Aeron.FragmentHandler() do _, buffer, _
                                push!(received3[], String(buffer))
                            end
                            wait_for(; timeout=10.0, sleep_s=0.05) do
                                Aeron.poll(replay_sub3, handler3, 10)
                                length(received3[]) >= 2
                            end
                            AeronArchive.stop_replay(archive, replay_id)
                            close(replay_sub3)

                            start_code = Integer(AeronArchive.ClientRecordingSignal.START)
                            stop_code = Integer(AeronArchive.ClientRecordingSignal.STOP)
                            wait_for(() -> (start_code in signals[]) && (stop_code in signals[]); timeout=10.0, sleep_s=0.05)

                            desc = desc_ref[]
                            @test desc !== nothing
                            base_pos = AeronArchive.segment_file_base_position(
                                desc.start_position,
                                desc.stop_position,
                                desc.term_buffer_length,
                                desc.segment_file_length,
                            )
                            @test AeronArchive.segment_file_base_position(
                                desc.start_position,
                                desc.start_position,
                                desc.term_buffer_length,
                                desc.segment_file_length,
                            ) == desc.start_position
                            if base_pos > desc.start_position
                                AeronArchive.detach_segments(archive, recording_id[], base_pos)
                                attach_count = AeronArchive.attach_segments(archive, recording_id[])
                                @test attach_count >= 0
                                purged = AeronArchive.purge_segments(archive, recording_id[], base_pos)
                                @test purged >= 0
                                wait_for(() -> AeronArchive.start_position(archive, recording_id[]) >= base_pos; timeout=10.0, sleep_s=0.05)
                                deleted = AeronArchive.delete_detached_segments(archive, recording_id[])
                                @test deleted >= 0
                            else
                                @test base_pos == desc.start_position
                            end

                            old_stop = AeronArchive.stop_position(archive, recording_id[])
                            truncate_pos = AeronArchive.start_position(archive, recording_id[])
                            truncated = AeronArchive.truncate_recording(archive, recording_id[], truncate_pos)
                            @test truncated >= 0
                            @test AeronArchive.stop_position(archive, recording_id[]) <= old_stop

                            AeronArchive.purge_recording(archive, recording_id[])
                            purged_seen = Ref(false)
                            purged_count = AeronArchive.list_recording((desc, _) -> begin
                                purged_seen[] = desc.recording_id == recording_id[]
                                nothing
                            end, archive, recording_id[])
                            @test purged_count == 0
                            @test !purged_seen[]

                            missing_id = Int64(999999999)
                            @test AeronArchive.list_recording((_, _) -> nothing, archive, missing_id) == 0
                            @test AeronArchive.list_recordings_for_uri((_, _) -> nothing, archive, missing_id, 10, "aeron:ipc", 1) == 0
                            @test_throws ErrorException AeronArchive.start_replay(archive, missing_id, "aeron:ipc", next_stream_id())
                            AeronArchive.stop_replay(archive, missing_id)
                            @test_throws ErrorException AeronArchive.truncate_recording(archive, missing_id, 0)
                            @test_throws ErrorException AeronArchive.purge_recording(archive, missing_id)
                        end
                    end
                end
            end
        end
    end
end
