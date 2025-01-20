module Aeron

include("LibAeron.jl")
using .LibAeron
using EnumX
using StringViews
using UnsafeArrays

"""
    launch_media_driver(;env=String[], wait=false) -> Process

Launch an aeron media driver process. A media driver is required for clients to communicate with each other.

See the aeron wiki at: https://github.com/real-logic/aeron/wiki/Configuration-Options for more information on configuring the media driver.

# Arguments
- `env`: A vector of strings containing environment variables to pass to the media driver.
- `wait`: If `true`, wait for the media driver to exit before returning. If `false`, return immediately and run the media driver in the background.
"""
function launch_media_driver(; env::Vector{String}=String[], wait=false)
    cmd = addenv(Aeron_jll.aeronmd_s(), env)
    process = run(`$(cmd)`; wait=wait)
    if !wait
        @async begin
            success(process)
        end
    end
    return process
end

include("client/aeronclient.jl")
include("archive/AeronArchive.jl")
include("driver/MediaDriver.jl")

end # module
