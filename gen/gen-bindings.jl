using Clang.Generators

using Aeron_jll

cd(@__DIR__)

include_dir = joinpath(Aeron_jll.artifact_dir, "include/aeron")

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()
push!(args, "-I$include_dir")

headers = joinpath(include_dir, "aeronc.h")

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
