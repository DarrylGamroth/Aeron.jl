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
    CnC,
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
    ImageView,
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
    add!,
    add_counter,
    add_destination,
    add_exclusive_publication,
    add_publication,
    add_subscription,
    add_subscription_view,
    aeron_dir,
    aeron_dir!,
    async_add_counter,
    async_add_destination,
    async_add_exclusive_publication,
    async_add_publication,
    async_add_subscription,
    async_add_subscription_view,
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
    compare_and_set!,
    context,
    correlation_id,
    counter_foreach,
    counter_id,
    counter_label,
    counter_owner_id,
    counter_reference_id,
    counter_registration_id,
    counter_state,
    counter_type_id,
    counter_value,
    counters_reader,
    decrement!,
    default_path,
    driver_timeout_ms,
    driver_timeout_ms!,
    exclusive_publication_limit_counter_id,
    find_counter_by_type_id_and_registration_id,
    frame_length,
    free_for_reuse_deadline_ms,
    get_and_add!,
    get_and_set!,
    idle_sleep_duration_ns,
    idle_sleep_duration_ns!,
    image_at_index,
    image_by_session_id,
    image_count,
    increment!,
    initial_term_id,
    is_end_of_stream,
    is_publication_revoked,
    is_connected,
    join_position,
    cnc_version,
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
    on_error!,
    on_fragment,
    on_new_exclusive_publication!,
    on_new_publication!,
    on_new_subscription!,
    on_unavailable_counter!,
    on_unavailable_image!,
    original_registration_id,
    poll,
    position,
    position!,
    position_bits_to_shift,
    position_limit,
    pid,
    pre_touch_mapped_memory,
    pre_touch_mapped_memory!,
    publication_limit_counter_id,
    registration_id,
    remove_destination,
    remove_destination_by_id,
    resource_linger_duration_ns,
    resource_linger_duration_ns!,
    file_page_size,
    revoke,
    revoke_on_close,
    session_id,
    set!,
    source_identity,
    start_timestamp,
    stream_id,
    subscriber_position_id,
    term_buffer_length,
    term_id,
    term_offset,
    try_claim,
    to_driver_heartbeat,
    version,
    version_gitsha,
    version_major,
    version_minor,
    version_patch,
    client_liveness_timeout,
    error_log_read,
    cnc_filename,
    loss_report_read,
    AeronArchive,
    MediaDriver

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
version_gitsha() = unsafe_string(aeron_version_gitsha())

"""
    default_path() -> String

    Get the default path for the Aeron media driver.

# Returns
- `String`: The default path for the Aeron media driver.
"""
function default_path()
    buffer = Vector{UInt8}(undef, 1024)
    GC.@preserve buffer begin
        result = aeron_default_path(Base.pointer(buffer), length(buffer))
        if result < 0
            throwerror()
        end
        return String(buffer[1:result])
    end
end

const PUBLICATION_NOT_CONNECTED = AERON_PUBLICATION_NOT_CONNECTED
const PUBLICATION_BACK_PRESSURED = AERON_PUBLICATION_BACK_PRESSURED
const PUBLICATION_ADMIN_ACTION = AERON_PUBLICATION_ADMIN_ACTION
const PUBLICATION_CLOSED = AERON_PUBLICATION_CLOSED
const PUBLICATION_MAX_POSITION_EXCEEDED = AERON_PUBLICATION_MAX_POSITION_EXCEEDED
const PUBLICATION_ERROR = AERON_PUBLICATION_ERROR

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
    uri::Union{Nothing,String}
end

include("exceptions.jl")
include("context.jl")
include("image.jl")
include("client.jl")
include("header.jl")
include("counter.jl")
include("countersreader.jl")
include("cnc.jl")
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
