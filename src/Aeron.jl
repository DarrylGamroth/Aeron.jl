module Aeron

using UnsafeArrays

include("LibAeron.jl")
using .LibAeron

throwerror() = (error(unsafe_string(aeron_errmsg())); nothing)

include("context.jl")
include("image.jl")
include("client.jl")
include("header.jl")
include("fragmentassembler.jl")

include("bufferclaim.jl")
include("publication.jl")
include("subscription.jl")

end # module