module Aeron

include("LibAeron.jl")
using .LibAeron

using EnumX
using StringViews
using UnsafeArrays

struct AsyncDestination
    async::Ptr{aeron_async_destination_t}
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
