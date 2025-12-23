using Aeron
using Test

const TEST_TIMEOUT_SEC = get(ENV, "AERON_TEST_TIMEOUT_SEC", "5.0") |> x -> parse(Float64, x)

const _stream_id_counter = Ref(Int32(1))

function next_stream_id()
    _stream_id_counter[] += 1
    return _stream_id_counter[]
end

function wait_for(predicate::Function; timeout::Float64=TEST_TIMEOUT_SEC, sleep_s::Float64=0.0)
    start_time = time()
    while true
        predicate() && return
        if time() - start_time > timeout
            error("Timed out waiting for condition")
        end
        if sleep_s > 0
            sleep(sleep_s)
        else
            yield()
        end
    end
end

function poll_for(predicate::Function; timeout::Float64=TEST_TIMEOUT_SEC)
    start_time = time()
    while true
        predicate() && return true
        if time() - start_time > timeout
            return false
        end
        yield()
    end
end

function with_embedded_driver(f::Function)
    Aeron.MediaDriver.launch_embedded() do driver
        f(driver)
    end
end

function with_client(f::Function; driver)
    Aeron.Context() do context
        Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
        Aeron.Client(context) do client
            f(client)
        end
    end
end

function ipc_channel()
    return "aeron:ipc"
end

function await_connected(pub, sub)
    wait_for(() -> Aeron.is_connected(pub) && Aeron.is_connected(sub))
end

function offer_until_success(pub, payload)
    result = Aeron.PUBLICATION_BACK_PRESSURED
    wait_for() do
        result = Aeron.offer(pub, payload)
        result > 0
    end
    return result
end

function offer_with_supplier_until_success(pub, payload, supplier)
    result = Aeron.PUBLICATION_BACK_PRESSURED
    wait_for() do
        result = Aeron.offer(pub, payload, supplier)
        result > 0
    end
    return result
end

function offer_vec_until_success(pub, buffers)
    result = Aeron.PUBLICATION_BACK_PRESSURED
    wait_for() do
        result = Aeron.offer(pub, buffers)
        result > 0
    end
    return result
end
