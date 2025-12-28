#!/usr/bin/env julia

using Aeron

function wait_for(predicate::Function; timeout::Float64=5.0)
    start_time = time()
    while true
        predicate() && return
        if time() - start_time > timeout
            error("Timed out waiting for condition")
        end
        yield()
    end
end

function run()
    Aeron.MediaDriver.launch_embedded() do driver
        Aeron.Context() do context
            Aeron.aeron_dir!(context, Aeron.MediaDriver.aeron_dir(driver))
            Aeron.Client(context) do client
                channel = "aeron:ipc"
                stream_id = 1001
                pub = Aeron.add_publication(client, channel, stream_id)
                sub = Aeron.add_subscription(client, channel, stream_id)

                wait_for(() -> Aeron.is_connected(pub) && Aeron.is_connected(sub))

                buffers = [fill(UInt8(0x1), 32) for _ in 1:16]
                tuple2 = (buffers[1], buffers[2])
                tuple3 = (buffers[1], buffers[2], buffers[3])
                tuple4 = (buffers[1], buffers[2], buffers[3], buffers[4])
                tuple5 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5])
                tuple6 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6])
                tuple7 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7])
                tuple8 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8])
                tuple9 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9])
                tuple10 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10])
                tuple11 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11])
                tuple12 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12])
                tuple13 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13])
                tuple14 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14])
                tuple15 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14], buffers[15])
                tuple16 = (buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14], buffers[15], buffers[16])
                vec2 = [buffers[1], buffers[2]]
                vec3 = [buffers[1], buffers[2], buffers[3]]
                vec4 = [buffers[1], buffers[2], buffers[3], buffers[4]]
                vec5 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5]]
                vec6 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6]]
                vec7 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7]]
                vec8 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8]]
                vec9 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9]]
                vec10 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10]]
                vec11 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11]]
                vec12 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12]]
                vec13 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13]]
                vec14 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14]]
                vec15 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14], buffers[15]]
                vec16 = [buffers[1], buffers[2], buffers[3], buffers[4], buffers[5], buffers[6], buffers[7], buffers[8], buffers[9], buffers[10], buffers[11], buffers[12], buffers[13], buffers[14], buffers[15], buffers[16]]

                for _ in 1:100
                    Aeron.offer(pub, buffers[1])
                    Aeron.offer(pub, tuple2)
                    Aeron.offer(pub, tuple3)
                    Aeron.offer(pub, tuple4)
                    Aeron.offer(pub, tuple5)
                    Aeron.offer(pub, tuple6)
                    Aeron.offer(pub, tuple7)
                    Aeron.offer(pub, tuple8)
                    Aeron.offer(pub, tuple9)
                    Aeron.offer(pub, tuple10)
                    Aeron.offer(pub, tuple11)
                    Aeron.offer(pub, tuple12)
                    Aeron.offer(pub, tuple13)
                    Aeron.offer(pub, tuple14)
                    Aeron.offer(pub, tuple15)
                    Aeron.offer(pub, tuple16)
                    Aeron.offer(pub, vec2)
                    Aeron.offer(pub, vec3)
                    Aeron.offer(pub, vec4)
                    Aeron.offer(pub, vec5)
                    Aeron.offer(pub, vec6)
                    Aeron.offer(pub, vec7)
                    Aeron.offer(pub, vec8)
                    Aeron.offer(pub, vec9)
                    Aeron.offer(pub, vec10)
                    Aeron.offer(pub, vec11)
                    Aeron.offer(pub, vec12)
                    Aeron.offer(pub, vec13)
                    Aeron.offer(pub, vec14)
                    Aeron.offer(pub, vec15)
                    Aeron.offer(pub, vec16)
                end

                GC.gc()
                alloc_single = @allocated Aeron.offer(pub, buffers[1])
                GC.gc()
                alloc_tuple2 = @allocated Aeron.offer(pub, tuple2)
                GC.gc()
                alloc_tuple3 = @allocated Aeron.offer(pub, tuple3)
                GC.gc()
                alloc_tuple4 = @allocated Aeron.offer(pub, tuple4)
                GC.gc()
                alloc_tuple5 = @allocated Aeron.offer(pub, tuple5)
                GC.gc()
                alloc_tuple6 = @allocated Aeron.offer(pub, tuple6)
                GC.gc()
                alloc_tuple7 = @allocated Aeron.offer(pub, tuple7)
                GC.gc()
                alloc_tuple8 = @allocated Aeron.offer(pub, tuple8)
                GC.gc()
                alloc_tuple9 = @allocated Aeron.offer(pub, tuple9)
                GC.gc()
                alloc_tuple10 = @allocated Aeron.offer(pub, tuple10)
                GC.gc()
                alloc_tuple11 = @allocated Aeron.offer(pub, tuple11)
                GC.gc()
                alloc_tuple12 = @allocated Aeron.offer(pub, tuple12)
                GC.gc()
                alloc_tuple13 = @allocated Aeron.offer(pub, tuple13)
                GC.gc()
                alloc_tuple14 = @allocated Aeron.offer(pub, tuple14)
                GC.gc()
                alloc_tuple15 = @allocated Aeron.offer(pub, tuple15)
                GC.gc()
                alloc_tuple16 = @allocated Aeron.offer(pub, tuple16)
                GC.gc()
                alloc_vec2 = @allocated Aeron.offer(pub, vec2)
                GC.gc()
                alloc_vec3 = @allocated Aeron.offer(pub, vec3)
                GC.gc()
                alloc_vec4 = @allocated Aeron.offer(pub, vec4)
                GC.gc()
                alloc_vec5 = @allocated Aeron.offer(pub, vec5)
                GC.gc()
                alloc_vec6 = @allocated Aeron.offer(pub, vec6)
                GC.gc()
                alloc_vec7 = @allocated Aeron.offer(pub, vec7)
                GC.gc()
                alloc_vec8 = @allocated Aeron.offer(pub, vec8)
                GC.gc()
                alloc_vec9 = @allocated Aeron.offer(pub, vec9)
                GC.gc()
                alloc_vec10 = @allocated Aeron.offer(pub, vec10)
                GC.gc()
                alloc_vec11 = @allocated Aeron.offer(pub, vec11)
                GC.gc()
                alloc_vec12 = @allocated Aeron.offer(pub, vec12)
                GC.gc()
                alloc_vec13 = @allocated Aeron.offer(pub, vec13)
                GC.gc()
                alloc_vec14 = @allocated Aeron.offer(pub, vec14)
                GC.gc()
                alloc_vec15 = @allocated Aeron.offer(pub, vec15)
                GC.gc()
                alloc_vec16 = @allocated Aeron.offer(pub, vec16)

                println("alloc_single_bytes=", alloc_single)
                println("alloc_tuple2_bytes=", alloc_tuple2)
                println("alloc_tuple3_bytes=", alloc_tuple3)
                println("alloc_tuple4_bytes=", alloc_tuple4)
                println("alloc_tuple5_bytes=", alloc_tuple5)
                println("alloc_tuple6_bytes=", alloc_tuple6)
                println("alloc_tuple7_bytes=", alloc_tuple7)
                println("alloc_tuple8_bytes=", alloc_tuple8)
                println("alloc_tuple9_bytes=", alloc_tuple9)
                println("alloc_tuple10_bytes=", alloc_tuple10)
                println("alloc_tuple11_bytes=", alloc_tuple11)
                println("alloc_tuple12_bytes=", alloc_tuple12)
                println("alloc_tuple13_bytes=", alloc_tuple13)
                println("alloc_tuple14_bytes=", alloc_tuple14)
                println("alloc_tuple15_bytes=", alloc_tuple15)
                println("alloc_tuple16_bytes=", alloc_tuple16)
                println("alloc_vec2_bytes=", alloc_vec2)
                println("alloc_vec3_bytes=", alloc_vec3)
                println("alloc_vec4_bytes=", alloc_vec4)
                println("alloc_vec5_bytes=", alloc_vec5)
                println("alloc_vec6_bytes=", alloc_vec6)
                println("alloc_vec7_bytes=", alloc_vec7)
                println("alloc_vec8_bytes=", alloc_vec8)
                println("alloc_vec9_bytes=", alloc_vec9)
                println("alloc_vec10_bytes=", alloc_vec10)
                println("alloc_vec11_bytes=", alloc_vec11)
                println("alloc_vec12_bytes=", alloc_vec12)
                println("alloc_vec13_bytes=", alloc_vec13)
                println("alloc_vec14_bytes=", alloc_vec14)
                println("alloc_vec15_bytes=", alloc_vec15)
                println("alloc_vec16_bytes=", alloc_vec16)
            end
        end
    end
end

run()
