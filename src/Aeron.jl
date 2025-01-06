module Aeron

include("LibAeron.jl")
using .LibAeron
using EnumX
using StringViews
using UnsafeArrays

export AbstractBlockHandler,
    AbstractControlledFragmentHandler,
    AbstractFragmentHandler,
    AbstractReservedValueSupplier,
    AeronException,
    AsyncAddCounter,
    AsyncAddExclusivePublication,
    AsyncAddPublication,
    AsyncAddSubscription,
    AsyncDestination,
    BlockHandler,
    BufferClaim,
    Client,
    ClientTimeoutException,
    ConductorServiceTimeoutException,
    Context,
    ControlledAction,
    ControlledFragmentAssembler,
    ControlledFragmentHandler,
    Counter,
    CounterState,
    CountersReader,
    DriverTimeoutException,
    ExclusivePublication,
    FragmentAssembler,
    FragmentHandler,
    GeneralAeronException,
    Header,
    IOException,
    IllegalStateException,
    Image,
    PUBLICATION_ADMIN_ACTION,
    PUBLICATION_BACK_PRESSURED,
    PUBLICATION_CLOSED,
    PUBLICATION_ERROR,
    PUBLICATION_MAX_POSITION_EXCEEDED,
    PUBLICATION_NOT_CONNECTED,
    Publication,
    ReservedValueSupplier,
    Subscription,
    TimedOutException,
    abort,
    add_counter,
    add_destination,
    add_exclusive_publication,
    add_publication,
    add_subscription,
    aeron_dir,
    aeron_dir!,
    async_add_counter,
    async_add_destination,
    async_add_exclusive_publication,
    async_add_publication,
    async_add_subscription,
    async_remove_destination,
    async_remove_destination_by_id,
    buffer,
    channel,
    channel_status,
    channel_status_indicator_id,
    client_id,
    client_name,
    clientd,
    commit,
    context,
    correlation_id,
    counter_foreach,
    counter_id,
    counter_key,
    counter_label,
    counter_owner_id,
    counter_reference_id,
    counter_registration_id,
    counter_state,
    counter_type_id,
    counter_value,
    default_path,
    driver_timeout_ms,
    driver_timeout_ms!,
    error_handler!,
    exclusive_publication_limit_counter_id,
    find_by_type_id_and_registration_id,
    frame_length,
    free_for_reuse_deadline_ms,
    idle_sleep_duration_ns,
    idle_sleep_duration_ns!,
    image_count,
    initial_term_id,
    is_connected,
    join_position,
    keepalive_internal_ns,
    keepalive_internal_ns!,
    launch_media_driver,
    max_counter_id,
    max_message_length,
    max_payload_length,
    max_possible_position,
    mtu_length,
    next_correlation_id,
    next_term_offset,
    offer,
    offer_block,
    on_available_counter!,
    on_available_image!,
    on_close_client!,
    on_fragment,
    on_new_exclusive_publication!,
    on_new_publication!,
    on_new_subscription!,
    on_unavailable_counter!,
    on_unavailable_image!,
    original_registration_id,
    poll,
    position,
    position_bits_to_shift,
    position_limit,
    pre_touch_mapped_memory,
    pre_touch_mapped_memory!,
    publication_limit_counter_id,
    registration_id,
    remove_destination,
    remove_destination_by_id,
    resource_linger_duration_ns,
    resource_linger_duration_ns!,
    session_id,
    source_identity,
    stream_id,
    subscriber_position_id,
    term_buffer_length,
    term_id,
    term_offset,
    try_claim,
    version,
    version_gitsha,
    version_major,
    version_minor,
    version_patch

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
@enumx ControlledAction::UInt32 begin
    ABORT = Integer(AERON_ACTION_ABORT)
    BREAK = Integer(AERON_ACTION_BREAK)
    COMMIT = Integer(AERON_ACTION_COMMIT)
    CONTINUE = Integer(AERON_ACTION_CONTINUE)
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
include("exclusivepublication.jl")

include("subscription.jl")

include("archive/AeronArchive.jl")

end # module
