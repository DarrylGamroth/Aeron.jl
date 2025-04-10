using Aeron
using Printf

include("samples_configuration.jl")

const USAGE_STR = """
[-h][-v][-c uri][-l linger][-m messages][-p prefix][-s stream-id]
    -h               help
    -v               show version and exit
    -f               use a message that will fill the whole MTU
    -c uri           use channel specified in uri
    -l linger        linger at end of publishing for linger seconds
    -m messages      number of messages to send
    -p prefix        aeron.dir location specified as prefix
    -s stream-id     stream-id to use
"""

Base.exit_on_sigint(false)

function build_large_message(len::Int)
    buf = zeros(UInt8, len + 1)

    if len < 2
        len = 2
    end

    limit = len
    buf[1] = UInt8('\n')
    len -= 1

    current_buf = 2
    line_counter = 0

    while limit > 0
        written = @sprintf("[%3d] This is a line of text fill out a large message to test whether large MTUs cause issues...\n", line_counter)
        written_len = length(written)

        if written_len > limit
            break
        end

        buf[current_buf:(current_buf+written_len-1)] .= Vector{UInt8}(written)

        limit -= written_len
        line_counter += 1
        current_buf += written_len
    end
    return buf[1:current_buf-1]
end

function main(ARGS)
    message = UInt8[]
    fill_mtu = false
    channel = DEFAULT_CHANNEL
    aeron_dir = nothing
    linger_ns = DEFAULT_LINGER_TIMEOUT_MS * 1000 * 1000
    messages = DEFAULT_NUMBER_OF_MESSAGES
    stream_id = DEFAULT_STREAM_ID

    args = ARGS
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "-c"
            i += 1
            channel = args[i]
        elseif arg == "-l"
            i += 1
            linger_ns = parse(Int, args[i]) * 1000 * 1000
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
        elseif arg == "-f"
            fill_mtu = true
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

    println("Publishing to channel $channel on Stream ID $stream_id")

    try
        Aeron.Context() do context
            if aeron_dir !== nothing
                Aeron.aeron_dir!(context, aeron_dir)
            end

            Aeron.Client(context) do aeron
                publication = Aeron.add_publication(aeron, channel, stream_id)

                println("Publication channel status ", Aeron.channel_status(publication))

                if fill_mtu
                    message = build_large_message(Aeron.max_payload_length(publication))
                    println("Using message of $(length(message)) bytes")
                end

                try
                    for i in 1:messages
                        if !fill_mtu
                            message = @sprintf("Hello World! %d", i)
                        end

                        print("offering $i/$messages - ")

                        result = Aeron.offer(publication, Vector{UInt8}(message))

                        if result > 0
                            println("yay!")
                        elseif result == Aeron.PUBLICATION_BACK_PRESSURED
                            println("Offer failed due to back pressure")
                        elseif result == Aeron.PUBLICATION_NOT_CONNECTED
                            println("Offer failed because publisher is not connected to a subscriber")
                        elseif result == Aeron.PUBLICATION_ADMIN_ACTION
                            println("Offer failed because of an administration action in the system")
                        elseif result == Aeron.PUBLICATION_CLOSED
                            println("Offer failed because publication is closed")
                        else
                            println("Offer failed due to unknown reason $result")
                        end

                        if !Aeron.is_connected(publication)
                            println("No active subscribers detected")
                        end

                        sleep(1)
                    end
                finally
                    close(publication)
                end

                println("Done sending.")

                if linger_ns > 0
                    println("Lingering for $linger_ns nanoseconds")
                    sleep(linger_ns / 1e9)
                end
            end
        end

    catch e
        if e isa InterruptException
            println("Done sending.")

            if linger_ns > 0
                println("Lingering for $linger_ns nanoseconds")
                sleep(linger_ns / 1e9)
            end
        else
            println("Error: ", e)
        end
    end

end
@main

@isdefined(var"@main") ? (@main) : exit(main(ARGS))