module Aeron

include("LibAeron.jl")
using .LibAeron

using EnumX
using StringViews
using UnsafeArrays

const PUBLICATION_NOT_CONNECTED = AERON_PUBLICATION_NOT_CONNECTED
const PUBLICATION_BACK_PRESSURED = AERON_PUBLICATION_BACK_PRESSURED
const PUBLICATION_ADMIN_ACTION = AERON_PUBLICATION_ADMIN_ACTION
const PUBLICATION_CLOSED = AERON_PUBLICATION_CLOSED
const PUBLICATION_MAX_POSITION_EXCEEDED = AERON_PUBLICATION_MAX_POSITION_EXCEEDED
const PUBLICATION_ERROR = AERON_PUBLICATION_ERROR

const IOVECS_NUM = 4

"""
    @enumx ControlledAction

Enumeration of possible actions that can be taken by a controlled fragment handler.

# Values

- `ABORT = 1`: Abort the current fragment processing.
- `BREAK = 2`: Break the current fragment processing loop.
- `COMMIT = 3`: Commit the current fragment processing.
- `CONTINUE = 4`: Continue processing the next fragment.
"""
@enumx ControlledAction begin
    ABORT = 1
    BREAK = 2
    COMMIT = 3
    CONTINUE = 4
end

struct AsyncDestination
    async::Ptr{aeron_async_destination_t}
end

"""
    version() -> String

Get the full version string of the Aeron library.

# Returns
- `String`: The Aeron version.
"""
version() = unsafe_string(aeron_version_full())

"""
    version_major() -> Int64

Get the major version of the Aeron library.

# Returns
- `Int64`: The major version.
"""
version_major() = aeron_version_major()

"""
    version_minor() -> Int64
    
Get the minor version of the Aeron library.

# Returns
- `Int64`: The minor version.
"""
version_minor() = aeron_version_minor()

"""
    version_patch() -> Int64

Get the patch version of the Aeron library.

# Returns
- `Int64`: The patch version.
"""
version_patch() = aeron_version_patch()

"""
    version_gitsha() -> String

Get the Git SHA of the Aeron library.

# Returns
- `String`: The Git SHA.
"""
version_gitsha() = unsafe_string(aeron_version_git_sha())

"""
    default_path() -> String

    Get the default path for the Aeron media driver.

# Returns
- `String`: The default path for the Aeron media driver.
"""
function default_path()
    buffer = Vector{UInt8}(undef, 1024)
    GC.@preserve buffer begin
        result = aeron_default_path(pointer(buffer), length(buffer))
        if result < 0
            throwerror()
        end
        return String(buffer[1:result])
    end
end

include("exceptions.jl")

include("context.jl")
include("image.jl")
include("client.jl")
include("header.jl")

include("counter.jl")
include("countersreader.jl")

include("fragmenthandler.jl")
include("controlledfragmenthandler.jl")

include("fragmentassembler.jl")
include("controlledfragmentassembler.jl")

include("blockhandler.jl")

include("bufferclaim.jl")
include("reservedvaluesupplier.jl")
include("publication.jl")

include("subscription.jl")

# for name in names(@__MODULE__; all=true)
#     println("$name,")
# end

end # module
