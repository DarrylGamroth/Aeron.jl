include("../src/Aeron.jl")

using .Aeron
using Printf

include("samples_util.jl")
include("samples_configuration.jl")

const USAGE_STR = """
[-h][-v][-c uri][-p prefix][-s stream-id]
    -h               help
    -v               show version and exit
    -c uri           use channel specified in uri
    -p prefix        aeron.dir location specified as prefix
    -s stream-id     stream-id to use
"""

Base.exit_on_sigint(false)

function poll_handler(subscription, buffer, header)
    stream_id = Aeron.stream_id(subscription)
    session_id = Aeron.session_id(header)
    len = length(buffer)
    println("Message to stream $stream_id from session $session_id ($len bytes) <<$(String(buffer))>>")
end

function main(ARGS)
    channel = DEFAULT_CHANNEL
    aeron_dir = nothing
    stream_id = DEFAULT_STREAM_ID

    args = ARGS
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "-c"
            i += 1
            channel = args[i]
        elseif arg == "-p"
            i += 1
            aeron_dir = args[i]
        elseif arg == "-s"
            i += 1
            stream_id = parse(Int, args[i])
        elseif arg == "-v"
            println("Aeron version: ", Aeron.version())
            return
        elseif arg == "-h"
            println("Usage: ", USAGE_STR)
            return
        else
            println("Unknown option: ", arg)
            println("Usage: ", USAGE_STR)
            return
        end
        i += 1
    end

    println("Subscribing to channel $channel on Stream ID $stream_id")

    try
        context = Aeron.Context()
        if aeron_dir !== nothing
            Aeron.aeron_dir!(context, aeron_dir)
        end

        Aeron.on_available_image!(print_available_image, context)
        Aeron.on_unavailable_image!(print_unavailable_image, context)

        aeron = Aeron.Client(context)
        subscription = Aeron.add_subscription(aeron, "aeron:udp?control-mode=manual", stream_id)
        Aeron.add_destination(subscription, channel)
        fragment_handler = Aeron.FragmentHandler(poll_handler, subscription)
        fragment_assembler = Aeron.FragmentAssembler(fragment_handler)

        println("Subscription channel status: ", Aeron.channel_status(subscription))

        while true
            Aeron.poll(subscription, fragment_assembler, DEFAULT_FRAGMENT_COUNT_LIMIT)
            sleep(0.001)  # 1ms
        end

    catch e
        if e isa InterruptException
            println("Shutting down...")
        else
            println("Error: ", e)
        end
    end

end
@main

@isdefined(var"@main") ? (@main) : exit(main(ARGS))