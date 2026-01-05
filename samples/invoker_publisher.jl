using Aeron
using Printf

include("samples_configuration.jl")

const USAGE_STR = """
[-h][-v][-c uri][-m messages][-p prefix][-s stream-id]
    -h               help
    -v               show version and exit
    -c uri           use channel specified in uri
    -m messages      number of messages to send
    -p prefix        aeron.dir location specified as prefix
    -s stream-id     stream-id to use
"""

Base.exit_on_sigint(false)

function idle_once()
    yield()
end

function main(ARGS)
    channel = DEFAULT_CHANNEL
    aeron_dir = nothing
    messages = DEFAULT_NUMBER_OF_MESSAGES
    stream_id = DEFAULT_STREAM_ID

    args = ARGS
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "-c"
            i += 1
            channel = args[i]
        elseif arg == "-m"
            i += 1
            messages = parse(Int, args[i])
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

    println("Publishing (invoker mode) to channel $channel on Stream ID $stream_id")

    Aeron.Context() do context
        Aeron.use_conductor_agent_invoker!(context, true)
        if aeron_dir !== nothing
            Aeron.aeron_dir!(context, aeron_dir)
        end

        Aeron.Client(context) do aeron
            publication = Aeron.add_publication(aeron, channel, stream_id)
            println("Publication channel status ", Aeron.channel_status(publication))

            sent = 0
            while sent < messages
                work = Aeron.do_work(aeron)
                if work == 0
                    idle_once()
                end

                message = @sprintf("Hello Invoker! %d", sent + 1)
                result = Aeron.offer(publication, Vector{UInt8}(message))

                if result > 0
                    sent += 1
                    println("offered $sent/$messages")
                elseif result == Aeron.PUBLICATION_BACK_PRESSURED
                    println("back pressured")
                elseif result == Aeron.PUBLICATION_NOT_CONNECTED
                    println("not connected")
                elseif result == Aeron.PUBLICATION_ADMIN_ACTION
                    println("admin action")
                elseif result == Aeron.PUBLICATION_CLOSED
                    println("publication closed")
                    return
                else
                    println("offer failed: $result")
                end
            end

            while Aeron.is_connected(publication)
                Aeron.do_work(aeron)
                idle_once()
            end
        end
    end
end

main(ARGS)
