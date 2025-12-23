module MediaDriver

using ..LibAeron
using ..Aeron
using EnumX
using UUIDs

export Context,
    Driver,
    InferableBoolean,
    MediaDriver,
    ThreadingMode,
    aeron_dir,
    aeron_dir!,
    async_executor_threads,
    async_executor_threads!,
    client_liveness_timeout_ns,
    client_liveness_timeout_ns!,
    clients_buffer_length,
    clients_buffer_length!,
    conductor_buffer_length,
    conductor_buffer_length!,
    conductor_cycle_threshold_ns,
    conductor_cycle_threshold_ns!,
    conductor_idle_strategy,
    conductor_idle_strategy!,
    conductor_idle_strategy_init_args,
    conductor_idle_strategy_init_args!,
    connect_enabled,
    connect_enabled!,
    counters_buffer_length,
    counters_buffer_length!,
    counters_free_to_reuse_timeout_ns,
    counters_free_to_reuse_timeout_ns!,
    dir_delete_on_shutdown,
    dir_delete_on_shutdown!,
    dir_delete_on_start,
    dir_delete_on_start!,
    dir_warn_if_exists,
    dir_warn_if_exists!,
    driver_timeout_ms,
    driver_timeout_ms!,
    do_work,
    enable_experimental_features,
    enable_experimental_features!,
    error_buffer_length,
    error_buffer_length!,
    file_page_size,
    file_page_size!,
    flow_control_group_min_size,
    flow_control_group_min_size!,
    flow_control_group_tag,
    flow_control_group_tag!,
    flow_control_receiver_timeout_ns,
    flow_control_receiver_timeout_ns!,
    image_liveness_timeout_ns,
    image_liveness_timeout_ns!,
    ipc_mtu_length,
    ipc_mtu_length!,
    ipc_publication_term_window_length,
    ipc_publication_term_window_length!,
    ipc_term_buffer_length,
    ipc_term_buffer_length!,
    loss_report_buffer_length,
    loss_report_buffer_length!,
    low_file_store_warning_threshold,
    low_file_store_warning_threshold!,
    main_idle_strategy,
    max_resend,
    max_resend!,
    mtu_length,
    mtu_length!,
    nak_multicast_group_size,
    nak_multicast_group_size!,
    nak_multicast_max_backoff_ns,
    nak_multicast_max_backoff_ns!,
    nak_unicast_delay_ns,
    nak_unicast_delay_ns!,
    nak_unicast_retry_delay_ratio,
    nak_unicast_retry_delay_ratio!,
    name_resolver_init_args,
    name_resolver_init_args!,
    name_resolver_threshold_ns,
    name_resolver_threshold_ns!,
    network_publication_max_messages_per_send,
    network_publication_max_messages_per_send!,
    perform_storage_checks,
    perform_storage_checks!,
    print_configuration,
    print_configuration!,
    publication_connection_timeout_ns,
    publication_connection_timeout_ns!,
    publication_linger_timeout_ns,
    publication_linger_timeout_ns!,
    publication_reserved_session_id_high,
    publication_reserved_session_id_high!,
    publication_reserved_session_id_low,
    publication_reserved_session_id_low!,
    publication_term_window_length,
    publication_term_window_length!,
    publication_unblock_timeout_ns,
    publication_unblock_timeout_ns!,
    rcv_initial_window_length,
    rcv_initial_window_length!,
    rcv_status_message_timeout_ns,
    rcv_status_message_timeout_ns!,
    re_resolution_check_interval_ns,
    re_resolution_check_interval_ns!,
    receiver_cycle_threshold_ns,
    receiver_cycle_threshold_ns!,
    receiver_group_consideration,
    receiver_group_consideration!,
    receiver_group_tag,
    receiver_group_tag!,
    receiver_group_tag_present,
    receiver_idle_strategy,
    receiver_idle_strategy!,
    receiver_idle_strategy_init_args,
    receiver_idle_strategy_init_args!,
    receiver_io_vector_capacity,
    receiver_io_vector_capacity!,
    receiver_wildcard_port_range,
    receiver_wildcard_port_range!,
    rejoin_stream,
    rejoin_stream!,
    reliable_stream,
    reliable_stream!,
    resolver_bootstrap_neighbor,
    resolver_bootstrap_neighbor!,
    resolver_interface,
    resolver_interface!,
    resolver_name,
    resolver_name!,
    resource_free_limit,
    resource_free_limit!,
    retransmit_unicast_delay_ns,
    retransmit_unicast_delay_ns!,
    retransmit_unicast_linger_ns,
    retransmit_unicast_linger_ns!,
    send_to_status_poll_ratio,
    send_to_status_poll_ratio!,
    sender_cycle_threshold_ns,
    sender_cycle_threshold_ns!,
    sender_idle_strategy,
    sender_idle_strategy!,
    sender_idle_strategy_init_args,
    sender_idle_strategy_init_args!,
    sender_io_vector_capacity,
    sender_io_vector_capacity!,
    sender_wildcard_port_range,
    sender_wildcard_port_range!,
    shared_idle_strategy,
    shared_idle_strategy!,
    shared_idle_strategy_init_args,
    shared_idle_strategy_init_args!,
    shared_network_idle_strategy,
    shared_network_idle_strategy!,
    shared_network_idle_strategy_init_args,
    shared_network_idle_strategy_init_args!,
    socket_multicast_ttl,
    socket_multicast_ttl!,
    socket_so_rcvbuf,
    socket_so_rcvbuf!,
    socket_so_sndbuf,
    socket_so_sndbuf!,
    spies_simulate_connection,
    spies_simulate_connection!,
    start,
    stream_session_limit,
    stream_session_limit!,
    term_buffer_length,
    term_buffer_length!,
    term_buffer_sparse_file,
    term_buffer_sparse_file!,
    tether_subscriptions,
    tether_subscriptions!,
    threading_mode,
    threading_mode!,
    timer_interval_ns,
    timer_interval_ns!,
    untethered_resting_timeout_ns,
    untethered_resting_timeout_ns!,
    untethered_window_limit_timeout_ns,
    untethered_window_limit_timeout_ns

struct Context
    context::Ptr{aeron_driver_context_t}

    function Context()
        p = Ref{Ptr{aeron_driver_context_t}}(C_NULL)
        if aeron_driver_context_init(p) < 0
            Aeron.throwerror()
        end
        new(p[])
    end
end

function Context(f::Function)
    c = Context()
    try
        f(c)
    finally
        close(c)
    end
end

function Base.close(c::Context)
    if aeron_driver_context_close(c.context) < 0
        Aeron.throwerror()
    end
end

Base.cconvert(::Type{Ptr{aeron_driver_context_t}}, c::Context) = c
Base.unsafe_convert(::Type{Ptr{aeron_driver_context_t}}, c::Context) = c.context

function _maybe_string(ptr::Cstring)
    return ptr == C_NULL ? nothing : unsafe_string(ptr)
end

"""
    aeron_dir!(c, dir)

Set the media driver directory for `Context`.

# Arguments
- `c`: The `Context` object.
- `dir`: The media driver directory.

# Throws
- `ErrorException` if `aeron_context_set_dir` fails.
"""
function aeron_dir!(c::Context, dir::AbstractString)
    if aeron_driver_context_set_dir(c.context, dir) < 0
        Aeron.throwerror()
    end
end

"""
    aeron_dir(c)

Get the directory used for the media driver for `Context`.

# Arguments
- `c`: The `Context` object.

# Returns
- The directory name of the `Context`, or `nothing` if unavailable.
"""
aeron_dir(c::Context) = _maybe_string(aeron_driver_context_get_dir(c.context))

function dir_warn_if_exists!(c::Context)
    if aeron_driver_context_get_dir_warn_if_exists(c.context) < 0
        Aeron.throwerror()
    end
end

dir_warn_if_exists(c::Context) = aeron_driver_context_get_dir_warn_if_exists(c.context)

@enumx ThreadingMode::UInt32 begin
    DEDICATED = Integer(AERON_THREADING_MODE_DEDICATED)
    SHARED_NETWORK = Integer(AERON_THREADING_MODE_SHARED_NETWORK)
    SHARED = Integer(AERON_THREADING_MODE_SHARED)
    INVOKER = Integer(AERON_THREADING_MODE_INVOKER)
end

function Base.convert(::Type{aeron_threading_mode_t}, mode::ThreadingMode.T)
    aeron_threading_mode_t(Integer(mode))
end

function Base.convert(::Type{ThreadingMode.T}, mode::aeron_threading_mode_t)
    ThreadingMode.T(Integer(mode))
end

function threading_mode!(c::Context, mode::ThreadingMode.T)
    if aeron_driver_context_set_threading_mode(c.context, mode) < 0
        Aeron.throwerror()
    end
end

threading_mode(c::Context) = convert(ThreadingMode.T, aeron_driver_context_get_threading_mode(c.context))

function dir_delete_on_start!(c::Context, value::Bool)
    if aeron_driver_context_set_dir_delete_on_start(c.context, value) < 0
        Aeron.throwerror()
    end
end

dir_delete_on_start(c::Context) = aeron_driver_context_get_dir_delete_on_start(c.context)

function dir_delete_on_shutdown!(c::Context, value::Bool)
    if aeron_driver_context_set_dir_delete_on_shutdown(c.context, value) < 0
        Aeron.throwerror()
    end
end

dir_delete_on_shutdown(c::Context) = aeron_driver_context_get_dir_delete_on_shutdown(c.context)

function conductor_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_to_conductor_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

conductor_buffer_length(c::Context) = aeron_driver_context_get_to_conductor_buffer_length(c.context)

function clients_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_to_clients_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

clients_buffer_length(c::Context) = aeron_driver_context_get_to_clients_buffer_length(c.context)

function counters_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_counters_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

counters_buffer_length(c::Context) = aeron_driver_context_get_counters_buffer_length(c.context)

function error_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_error_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

error_buffer_length(c::Context) = aeron_driver_context_get_error_buffer_length(c.context)

function client_liveness_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_client_liveness_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

client_liveness_timeout_ns(c::Context) = aeron_driver_context_get_client_liveness_timeout_ns(c.context)

function term_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_term_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

term_buffer_length(c::Context) = aeron_driver_context_get_term_buffer_length(c.context)

function ipc_term_buffer_length!(c::Context, len::Int)
    if aeron_driver_context_set_ipc_term_buffer_length(c.context, len) < 0
        Aeron.throwerror()
    end
end

ipc_term_buffer_length(c::Context) = aeron_driver_context_get_ipc_term_buffer_length(c.context)

function term_buffer_sparse_file!(c::Context, value::Bool)
    if aeron_driver_context_set_term_buffer_sparse_file(c.context, value) < 0
        Aeron.throwerror()
    end
end

term_buffer_sparse_file(c::Context) = aeron_driver_context_get_term_buffer_sparse_file(c.context)

function perform_storage_checks!(c::Context, value::Bool)
    if aeron_driver_context_set_perform_storage_checks(c.context, value) < 0
        Aeron.throwerror()
    end
end

perform_storage_checks(c::Context) = aeron_driver_context_get_perform_storage_checks(c.context)

function low_file_store_warning_threshold!(c::Context, threshold::Int)
    if aeron_driver_context_set_low_file_store_warning_threshold(c.context, threshold) < 0
        Aeron.throwerror()
    end
end

low_file_store_warning_threshold(c::Context) = aeron_driver_context_get_low_file_store_warning_threshold(c.context)

function spies_simulate_connection!(c::Context, value::Bool)
    if aeron_driver_context_set_spies_simulate_connection(c.context, value) < 0
        Aeron.throwerror()
    end
end

spies_simulate_connection(c::Context) = aeron_driver_context_get_spies_simulate_connection(c.context)

function file_page_size!(c::Context, size::Int)
    if aeron_driver_context_set_file_page_size(c.context, size) < 0
        Aeron.throwerror()
    end
end

file_page_size(c::Context) = aeron_driver_context_get_file_page_size(c.context)

function mtu_length!(c::Context, length::Int)
    if aeron_driver_context_set_mtu_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

mtu_length(c::Context) = aeron_driver_context_get_mtu_length(c.context)

function ipc_mtu_length!(c::Context, length::Int)
    if aeron_driver_context_set_ipc_mtu_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

ipc_mtu_length(c::Context) = aeron_driver_context_get_ipc_mtu_length(c.context)

function ipc_publication_term_window_length!(c::Context, length::Int)
    if aeron_driver_context_set_ipc_publication_term_window_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

ipc_publication_term_window_length(c::Context) = aeron_driver_context_get_ipc_publication_term_window_length(c.context)

function publication_term_window_length!(c::Context, length::Int)
    if aeron_driver_context_set_publication_term_window_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

publication_term_window_length(c::Context) = aeron_driver_context_get_publication_term_window_length(c.context)

function publication_linger_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_publication_linger_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

publication_linger_timeout_ns(c::Context) = aeron_driver_context_get_publication_linger_timeout_ns(c.context)

function socket_so_rcvbuf!(c::Context, size::Int)
    if aeron_driver_context_set_socket_so_rcvbuf(c.context, size) < 0
        Aeron.throwerror()
    end
end

socket_so_rcvbuf(c::Context) = aeron_driver_context_get_socket_so_rcvbuf(c.context)

function socket_so_sndbuf!(c::Context, size::Int)
    if aeron_driver_context_set_socket_so_sndbuf(c.context, size) < 0
        Aeron.throwerror()
    end
end

socket_so_sndbuf(c::Context) = aeron_driver_context_get_socket_so_sndbuf(c.context)

function socket_multicast_ttl!(c::Context, ttl::Int)
    if aeron_driver_context_set_socket_multicast_ttl(c.context, ttl) < 0
        Aeron.throwerror()
    end
end

socket_multicast_ttl(c::Context) = aeron_driver_context_get_socket_multicast_ttl(c.context)

function send_to_status_poll_ratio!(c::Context, ratio::Int)
    if aeron_driver_context_set_send_to_status_poll_ratio(c.context, ratio) < 0
        Aeron.throwerror()
    end
end

send_to_status_poll_ratio(c::Context) = aeron_driver_context_get_send_to_status_poll_ratio(c.context)

function rcv_status_message_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_rcv_status_message_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

rcv_status_message_timeout_ns(c::Context) = aeron_driver_context_get_rcv_status_message_timeout_ns(c.context)


function image_liveness_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_image_liveness_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

image_liveness_timeout_ns(c::Context) = aeron_driver_context_get_image_liveness_timeout_ns(c.context)

function rcv_initial_window_length!(c::Context, length::Int)
    if aeron_driver_context_set_rcv_initial_window_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

rcv_initial_window_length(c::Context) = aeron_driver_context_get_rcv_initial_window_length(c.context)

function loss_report_buffer_length!(c::Context, length::Int)
    if aeron_driver_context_set_loss_report_buffer_length(c.context, length) < 0
        Aeron.throwerror()
    end
end

loss_report_buffer_length(c::Context) = aeron_driver_context_get_loss_report_buffer_length(c.context)

function publication_unblock_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_publication_unblock_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

publication_unblock_timeout_ns(c::Context) = aeron_driver_context_get_publication_unblock_timeout_ns(c.context)

function publication_connection_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_publication_connection_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

publication_connection_timeout_ns(c::Context) = aeron_driver_context_get_publication_connection_timeout_ns(c.context)

function timer_interval_ns!(c::Context, interval::Int)
    if aeron_driver_context_set_timer_interval_ns(c.context, interval) < 0
        Aeron.throwerror()
    end
end

timer_interval_ns(c::Context) = aeron_driver_context_get_timer_interval_ns(c.context)

function sender_idle_strategy!(c::Context, value::AbstractString)
    if aeron_driver_context_set_sender_idle_strategy(c.context, value) < 0
        Aeron.throwerror()
    end
end

sender_idle_strategy(c::Context) = _maybe_string(aeron_driver_context_get_sender_idle_strategy(c.context))

function conductor_idle_strategy!(c::Context, value::AbstractString)
    if aeron_driver_context_set_conductor_idle_strategy(c.context, value) < 0
        Aeron.throwerror()
    end
end

conductor_idle_strategy(c::Context) = _maybe_string(aeron_driver_context_get_conductor_idle_strategy(c.context))

function receiver_idle_strategy!(c::Context, value::AbstractString)
    if aeron_driver_context_set_receiver_idle_strategy(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_idle_strategy(c::Context) = _maybe_string(aeron_driver_context_get_receiver_idle_strategy(c.context))

function shared_network_idle_strategy!(c::Context, value::AbstractString)
    if aeron_driver_context_set_sharednetwork_idle_strategy(c.context, value) < 0
        Aeron.throwerror()
    end
end

shared_network_idle_strategy(c::Context) = _maybe_string(aeron_driver_context_get_sharednetwork_idle_strategy(c.context))

function shared_idle_strategy!(c::Context, value::AbstractString)
    if aeron_driver_context_set_shared_idle_strategy(c.context, value) < 0
        Aeron.throwerror()
    end
end

shared_idle_strategy(c::Context) = _maybe_string(aeron_driver_context_get_shared_idle_strategy(c.context))

function sender_idle_strategy_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_sender_idle_strategy_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

sender_idle_strategy_init_args(c::Context) = _maybe_string(aeron_driver_context_get_sender_idle_strategy_init_args(c.context))

function conductor_idle_strategy_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_conductor_idle_strategy_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

conductor_idle_strategy_init_args(c::Context) = _maybe_string(aeron_driver_context_get_conductor_idle_strategy_init_args(c.context))

function receiver_idle_strategy_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_receiver_idle_strategy_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_idle_strategy_init_args(c::Context) = _maybe_string(aeron_driver_context_get_receiver_idle_strategy_init_args(c.context))

function shared_network_idle_strategy_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_sharednetwork_idle_strategy_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

shared_network_idle_strategy_init_args(c::Context) = _maybe_string(aeron_driver_context_get_sharednetwork_idle_strategy_init_args(c.context))

function shared_idle_strategy_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_shared_idle_strategy_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

shared_idle_strategy_init_args(c::Context) = _maybe_string(aeron_driver_context_get_shared_idle_strategy_init_args(c.context))

function counters_free_to_reuse_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_counters_free_to_reuse_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

counters_free_to_reuse_timeout_ns(c::Context) = aeron_driver_context_get_counters_free_to_reuse_timeout_ns(c.context)

function flow_control_receiver_timeout_ns!(c::Context, timeout::Int)
    if aeron_driver_context_set_flow_control_receiver_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

flow_control_receiver_timeout_ns(c::Context) = aeron_driver_context_get_flow_control_receiver_timeout_ns(c.context)

function flow_control_group_tag!(c::Context, tag::Int)
    if aeron_driver_context_set_flow_control_group_tag(c.context, tag) < 0
        Aeron.throwerror()
    end
end

flow_control_group_tag(c::Context) = aeron_driver_context_get_flow_control_group_tag(c.context)

function flow_control_group_min_size!(c::Context, size::Int)
    if aeron_driver_context_set_flow_control_group_min_size(c.context, size) < 0
        Aeron.throwerror()
    end
end

flow_control_group_min_size(c::Context) = aeron_driver_context_get_flow_control_group_min_size(c.context)

function receiver_group_tag!(c::Context, is_present::Bool, tag::Int)
    if aeron_driver_context_set_receiver_group_tag(c.context, is_present, tag) < 0
        Aeron.throwerror()
    end
end

receiver_group_tag_present(c::Context) = aeron_driver_context_get_receiver_group_tag_is_present(c.context)
receiver_group_tag(c::Context) = aeron_driver_context_get_receiver_group_tag_value(c.context)

function print_configuration!(c::Context, value::Bool)
    if aeron_driver_context_print_configuration(c.context, value) < 0
        Aeron.throwerror()
    end
end

print_configuration(c::Context) = aeron_driver_context_get_print_configuration(c.context)

function reliable_stream!(c::Context, value::Bool)
    if aeron_driver_context_set_reliable_stream(c.context, value) < 0
        Aeron.throwerror()
    end
end

reliable_stream(c::Context) = aeron_driver_context_get_reliable_stream(c.context)

function tether_subscriptions!(c::Context, value::Bool)
    if aeron_driver_context_set_tether_subscriptions(c.context, value) < 0
        Aeron.throwerror()
    end
end

tether_subscriptions(c::Context) = aeron_driver_context_get_tether_subscriptions(c.context)

function untethered_window_limit_timeout_ns!(c::Context, timeout::UInt64)
    if aeron_driver_context_set_untethered_window_limit_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

untethered_window_limit_timeout_ns(c::Context) = aeron_driver_context_get_untethered_window_limit_timeout_ns(c.context)

function untethered_resting_timeout_ns!(c::Context, timeout::UInt64)
    if aeron_driver_context_set_untethered_resting_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

untethered_linger_timeout_ns(c::Context) = aeron_driver_context_get_untethered_linger_timeout_ns(c.context)

function untethered_linger_timeout_ns!(c::Context, timeout::UInt64)
    if aeron_driver_context_set_untethered_linger_timeout_ns(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

untethered_resting_timeout_ns(c::Context) = aeron_driver_context_get_untethered_resting_timeout_ns(c.context)

function driver_timeout_ms!(c::Context, timeout::UInt64)
    if aeron_driver_context_set_driver_timeout_ms(c.context, timeout) < 0
        Aeron.throwerror()
    end
end

driver_timeout_ms(c::Context) = aeron_driver_context_get_driver_timeout_ms(c.context)

function nak_multicast_group_size!(c::Context, value::Csize_t)
    if aeron_driver_context_set_nak_multicast_group_size(c.context, value) < 0
        Aeron.throwerror()
    end
end

nak_multicast_group_size(c::Context) = aeron_driver_context_get_nak_multicast_group_size(c.context)

function nak_multicast_max_backoff_ns!(c::Context, value::UInt64)
    if aeron_driver_context_set_nak_multicast_max_backoff_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

nak_multicast_max_backoff_ns(c::Context) = aeron_driver_context_get_nak_multicast_max_backoff_ns(c.context)

function nak_unicast_delay_ns!(c::Context, value::UInt64)
    if aeron_driver_context_set_nak_unicast_delay_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

nak_unicast_delay_ns(c::Context) = aeron_driver_context_get_nak_unicast_delay_ns(c.context)

function nak_unicast_retry_delay_ratio!(c::Context, value::UInt64)
    if aeron_driver_context_set_nak_unicast_retry_delay_ratio(c.context, value) < 0
        Aeron.throwerror()
    end
end

nak_unicast_retry_delay_ratio(c::Context) = aeron_driver_context_get_nak_unicast_retry_delay_ratio(c.context)

function max_resend!(c::Context, value::Int)
    if aeron_driver_context_set_max_resend(c.context, value) < 0
        Aeron.throwerror()
    end
end

max_resend(c::Context) = aeron_driver_context_get_max_resend(c.context)

function retransmit_unicast_delay_ns!(c::Context, value::UInt64)
    if aeron_driver_context_set_retransmit_unicast_delay_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

retransmit_unicast_delay_ns(c::Context) = aeron_driver_context_get_retransmit_unicast_delay_ns(c.context)

function retransmit_unicast_linger_ns!(c::Context, value::UInt64)
    if aeron_driver_context_set_retransmit_unicast_linger_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

retransmit_unicast_linger_ns(c::Context) = aeron_driver_context_get_retransmit_unicast_linger_ns(c.context)

@enumx InferableBoolean::UInt32 begin
    FORCE_FALSE = Integer(AERON_FORCE_FALSE)
    FORCE_TRUE = Integer(AERON_FORCE_TRUE)
    INFER = Integer(AERON_INFER)
end

function Base.convert(::Type{aeron_inferable_boolean_t}, value::InferableBoolean.T)
    aeron_inferable_boolean_t(Integer(value))
end

function Base.convert(::Type{InferableBoolean.T}, value::aeron_inferable_boolean_t)
    InferableBoolean(value)
end

function receiver_group_consideration!(c::Context, value::InferableBoolean.T)
    if aeron_driver_context_set_receiver_group_consideration(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_group_consideration(c::Context) = InferableBoolean.T(Integer(aeron_driver_context_get_receiver_group_consideration(c.context)))

function rejoin_stream!(c::Context, value::Bool)
    if aeron_driver_context_set_rejoin_stream(c.context, value) < 0
        Aeron.throwerror()
    end
end

rejoin_stream(c::Context) = aeron_driver_context_get_rejoin_stream(c.context)

function connect_enabled!(c::Context, value::Bool)
    if aeron_driver_context_set_connect_enabled(c.context, value) < 0
        Aeron.throwerror()
    end
end

connect_enabled(c::Context) = aeron_driver_context_get_connect_enabled(c.context)

function publication_reserved_session_id_low!(c::Context, value::Int)
    if aeron_driver_context_set_publication_reserved_session_id_low(c.context, value) < 0
        Aeron.throwerror()
    end
end

publication_reserved_session_id_low(c::Context) = aeron_driver_context_get_publication_reserved_session_id_low(c.context)

function publication_reserved_session_id_high!(c::Context, value::Int)
    if aeron_driver_context_set_publication_reserved_session_id_high(c.context, value) < 0
        Aeron.throwerror()
    end
end

publication_reserved_session_id_high(c::Context) = aeron_driver_context_get_publication_reserved_session_id_high(c.context)

function resolver_name!(c::Context, value::AbstractString)
    if aeron_driver_context_set_resolver_name(c.context, value) < 0
        Aeron.throwerror()
    end
end

function resolver_name(c::Context)
    aeron_driver_context_get_resolver_name(c.context) == C_NULL ?
    nothing :
    unsafe_string(aeron_driver_context_get_resolver_name(c.context))
end

function resolver_interface!(c::Context, value::AbstractString)
    if aeron_driver_context_set_resolver_interface(c.context, value) < 0
        Aeron.throwerror()
    end
end

function resolver_interface(c::Context)
    aeron_driver_context_get_resolver_interface(c.context) == C_NULL ?
    nothing :
    unsafe_string(aeron_driver_context_get_resolver_interface(c.context))
end

function resolver_bootstrap_neighbor!(c::Context, value::AbstractString)
    if aeron_driver_context_set_resolver_bootstrap_neighbor(c.context, value) < 0
        Aeron.throwerror()
    end
end

function resolver_bootstrap_neighbor(c::Context)
    aeron_driver_context_get_resolver_bootstrap_neighbor(c.context) == C_NULL ?
    nothing :
    unsafe_string(aeron_driver_context_get_resolver_bootstrap_neighbor(c.context))
end

function name_resolver_init_args!(c::Context, value::AbstractString)
    if aeron_driver_context_set_name_resolver_init_args(c.context, value) < 0
        Aeron.throwerror()
    end
end

name_resolver_init_args(c::Context) = _maybe_string(aeron_driver_context_get_name_resolver_init_args(c.context))

function re_resolution_check_interval_ns!(c::Context, value::Int)
    if aeron_driver_context_set_re_resolution_check_interval_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

re_resolution_check_interval_ns(c::Context) = aeron_driver_context_get_re_resolution_check_interval_ns(c.context)

function sender_wildcard_port_range!(c::Context, low_port::Int, high_port::Int)
    if aeron_driver_context_set_sender_wildcard_port_range(c.context, low_port, high_port) < 0
        Aeron.throwerror()
    end
end

function sender_wildcard_port_range(c::Context)
    low_port = Ref{UInt16}()
    high_port = Ref{UInt16}()
    if aeron_driver_context_get_sender_wildcard_port_range(c.context, low_port, high_port) < 0
        Aeron.throwerror()
    end
    (low_port[], high_port[])
end

function receiver_wildcard_port_range!(c::Context, low_port::Int, high_port::Int)
    if aeron_driver_context_set_receiver_wildcard_port_range(c.context, low_port, high_port) < 0
        Aeron.throwerror()
    end
end

function receiver_wildcard_port_range(c::Context)
    low_port = Ref{UInt16}()
    high_port = Ref{UInt16}()
    if aeron_driver_context_get_receiver_wildcard_port_range(c.context, low_port, high_port) < 0
        Aeron.throwerror()
    end
    (low_port[], high_port[])
end

function conductor_cycle_threshold_ns!(c::Context, value::Int)
    if aeron_driver_context_set_conductor_cycle_threshold_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

conductor_cycle_threshold_ns(c::Context) = aeron_driver_context_get_conductor_cycle_threshold_ns(c.context)

function sender_cycle_threshold_ns!(c::Context, value::Int)
    if aeron_driver_context_set_sender_cycle_threshold_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

sender_cycle_threshold_ns(c::Context) = aeron_driver_context_get_sender_cycle_threshold_ns(c.context)

function receiver_cycle_threshold_ns!(c::Context, value::Int)
    if aeron_driver_context_set_receiver_cycle_threshold_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_cycle_threshold_ns(c::Context) = aeron_driver_context_get_receiver_cycle_threshold_ns(c.context)

function name_resolver_threshold_ns!(c::Context, value::Int)
    if aeron_driver_context_set_name_resolver_threshold_ns(c.context, value) < 0
        Aeron.throwerror()
    end
end

name_resolver_threshold_ns(c::Context) = aeron_driver_context_get_name_resolver_threshold_ns(c.context)

function receiver_io_vector_capacity!(c::Context, value::Int)
    if aeron_driver_context_set_receiver_io_vector_capacity(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_io_vector_capacity(c::Context) = aeron_driver_context_get_receiver_io_vector_capacity(c.context)

function sender_io_vector_capacity!(c::Context, value::Int)
    if aeron_driver_context_set_sender_io_vector_capacity(c.context, value) < 0
        Aeron.throwerror()
    end
end

sender_io_vector_capacity(c::Context) = aeron_driver_context_get_sender_io_vector_capacity(c.context)

function network_publication_max_messages_per_send!(c::Context, value::Int)
    if aeron_driver_context_set_network_publication_max_messages_per_send(c.context, value) < 0
        Aeron.throwerror()
    end
end

network_publication_max_messages_per_send(c::Context) = aeron_driver_context_get_network_publication_max_messages_per_send(c.context)

function resource_free_limit!(c::Context, value::Int)
    if aeron_driver_context_set_resource_free_limit(c.context, value) < 0
        Aeron.throwerror()
    end
end

resource_free_limit(c::Context) = aeron_driver_context_get_resource_free_limit(c.context)

function async_executor_threads!(c::Context, value::Int)
    if aeron_driver_context_set_async_executor_threads(c.context, value) < 0
        Aeron.throwerror()
    end
end

async_executor_threads(c::Context) = aeron_driver_context_get_async_executor_threads(c.context)

function conductor_cpu_affinity!(c::Context, value::Int)
    if aeron_driver_context_set_conductor_cpu_affinity(c.context, value) < 0
        Aeron.throwerror()
    end
end

conductor_cpu_affinity(c::Context) = aeron_driver_context_get_conductor_cpu_affinity(c.context)

function receiver_cpu_affinity!(c::Context, value::Int)
    if aeron_driver_context_set_receiver_cpu_affinity(c.context, value) < 0
        Aeron.throwerror()
    end
end

receiver_cpu_affinity(c::Context) = aeron_driver_context_get_receiver_cpu_affinity(c.context)

function sender_cpu_affinity!(c::Context, value::Int)
    if aeron_driver_context_set_sender_cpu_affinity(c.context, value) < 0
        Aeron.throwerror()
    end
end

sender_cpu_affinity(c::Context) = aeron_driver_context_get_sender_cpu_affinity(c.context)

function enable_experimental_features!(c::Context, value::Bool)
    if aeron_driver_context_set_enable_experimental_features(c.context, value) < 0
        Aeron.throwerror()
    end
end

enable_experimental_features(c::Context) = aeron_driver_context_get_enable_experimental_features(c.context)

function stream_session_limit!(c::Context, value::Int)
    if aeron_driver_context_set_stream_session_limit(c.context, value) < 0
        Aeron.throwerror()
    end
end

stream_session_limit(c::Context) = aeron_driver_context_get_stream_session_limit(c.context)

function Base.show(io::IO, c::Context)
    println(io, "Context")
    println(io, "  aeron dir: ", aeron_dir(c))
    println(io, "  threading mode: ", threading_mode(c))
    println(io, "  dir delete on start: ", dir_delete_on_start(c))
    println(io, "  dir delete on shutdown: ", dir_delete_on_shutdown(c))
    println(io, "  conductor buffer length: ", conductor_buffer_length(c))
    println(io, "  clients buffer length: ", clients_buffer_length(c))
    println(io, "  counters buffer length: ", counters_buffer_length(c))
    println(io, "  error buffer length: ", error_buffer_length(c))
    println(io, "  client liveness timeout ns: ", client_liveness_timeout_ns(c))
    println(io, "  term buffer length: ", term_buffer_length(c))
    println(io, "  ipc term buffer length: ", ipc_term_buffer_length(c))
    println(io, "  term buffer sparse file: ", term_buffer_sparse_file(c))
    println(io, "  perform storage checks: ", perform_storage_checks(c))
    println(io, "  low file store warning threshold: ", low_file_store_warning_threshold(c))
    println(io, "  spies simulate connection: ", spies_simulate_connection(c))
    println(io, "  file page size: ", file_page_size(c))
    println(io, "  mtu length: ", mtu_length(c))
    println(io, "  ipc mtu length: ", ipc_mtu_length(c))
    println(io, "  ipc publication term window length: ", ipc_publication_term_window_length(c))
    println(io, "  publication term window length: ", publication_term_window_length(c))
    println(io, "  publication linger timeout ns: ", publication_linger_timeout_ns(c))
    println(io, "  socket so rcvbuf: ", socket_so_rcvbuf(c))
    println(io, "  socket so sndbuf: ", socket_so_sndbuf(c))
    println(io, "  socket multicast ttl: ", socket_multicast_ttl(c))
    println(io, "  send to status poll ratio: ", send_to_status_poll_ratio(c))
    println(io, "  rcv status message timeout ns: ", rcv_status_message_timeout_ns(c))
    println(io, "  image liveness timeout ns: ", image_liveness_timeout_ns(c))
    println(io, "  rcv initial window length: ", rcv_initial_window_length(c))
    println(io, "  loss report buffer length: ", loss_report_buffer_length(c))
    println(io, "  publication unblock timeout ns: ", publication_unblock_timeout_ns(c))
    println(io, "  publication connection timeout ns: ", publication_connection_timeout_ns(c))
    println(io, "  timer interval ns: ", timer_interval_ns(c))
    println(io, "  sender idle strategy: ", sender_idle_strategy(c))
    println(io, "  conductor idle strategy: ", conductor_idle_strategy(c))
    println(io, "  receiver idle strategy: ", receiver_idle_strategy(c))
    println(io, "  shared network idle strategy: ", shared_network_idle_strategy(c))
    println(io, "  shared idle strategy: ", shared_idle_strategy(c))
    println(io, "  counters free to reuse timeout ns: ", counters_free_to_reuse_timeout_ns(c))
    println(io, "  flow control receiver timeout ns: ", flow_control_receiver_timeout_ns(c))
    println(io, "  flow control group tag: ", flow_control_group_tag(c))
    println(io, "  flow control group min size: ", flow_control_group_min_size(c))
    println(io, "  receiver group tag: ", receiver_group_tag_present(c) ? receiver_group_tag(c) : "")
    println(io, "  print configuration: ", print_configuration(c))
    println(io, "  reliable stream: ", reliable_stream(c))
    println(io, "  tether subscriptions: ", tether_subscriptions(c))
    println(io, "  untethered window limit timeout ns: ", untethered_window_limit_timeout_ns(c))
    println(io, "  untethered resting timeout ns: ", untethered_resting_timeout_ns(c))
    println(io, "  driver timeout ms: ", driver_timeout_ms(c))
    println(io, "  nak multicast group size: ", nak_multicast_group_size(c))
    println(io, "  nak multicast max backoff ns: ", nak_multicast_max_backoff_ns(c))
    println(io, "  nak unicast delay ns: ", nak_unicast_delay_ns(c))
    println(io, "  nak unicast retry delay ratio: ", nak_unicast_retry_delay_ratio(c))
    println(io, "  max resend: ", max_resend(c))
    println(io, "  retransmit unicast delay ns: ", retransmit_unicast_delay_ns(c))
    println(io, "  retransmit unicast linger ns: ", retransmit_unicast_linger_ns(c))
    println(io, "  receiver group consideration: ", receiver_group_consideration(c))
    println(io, "  rejoin stream: ", rejoin_stream(c))
    println(io, "  connect enabled: ", connect_enabled(c))
    println(io, "  publication reserved session id low: ", publication_reserved_session_id_low(c))
    println(io, "  publication reserved session id high: ", publication_reserved_session_id_high(c))
    println(io, "  resolver name: ", resolver_name(c))
    println(io, "  resolver interface: ", resolver_interface(c))
    println(io, "  resolver bootstrap neighbor: ", resolver_bootstrap_neighbor(c))
    println(io, "  re-resolution check interval ns: ", re_resolution_check_interval_ns(c))
    println(io, "  sender wildcard port range: ", sender_wildcard_port_range(c))
    println(io, "  receiver wildcard port range: ", receiver_wildcard_port_range(c))
    println(io, "  conductor cycle threshold ns: ", conductor_cycle_threshold_ns(c))
    println(io, "  sender cycle threshold ns: ", sender_cycle_threshold_ns(c))
    println(io, "  receiver cycle threshold ns: ", receiver_cycle_threshold_ns(c))
    println(io, "  name resolver threshold ns: ", name_resolver_threshold_ns(c))
    println(io, "  receiver io vector capacity: ", receiver_io_vector_capacity(c))
    println(io, "  sender io vector capacity: ", sender_io_vector_capacity(c))
    println(io, "  network publication max messages per send: ", network_publication_max_messages_per_send(c))
    println(io, "  resource free limit: ", resource_free_limit(c))
    println(io, "  async executor threads: ", async_executor_threads(c))
    println(io, "  enable experimental features: ", enable_experimental_features(c))
    println(io, "  stream session limit: ", stream_session_limit(c))
end

struct Driver
    driver::Ptr{aeron_driver_t}
    context::Context

    function Driver(context::Context)
        p = Ref{Ptr{aeron_driver_t}}(C_NULL)
        if aeron_driver_init(p, context.context) < 0
            Aeron.throwerror()
        end
        return new(p[], context)
    end
end

function Driver(f::Function, context::Context)
    d = Driver(context)
    try
        f(d)
    finally
        close(d)
    end
end

function Driver(f::Function)
    Context() do context
        d = Driver(context)
        try
            f(d)
        finally
            close(d)
        end
    end
end

function Base.close(d::Driver)
    if aeron_driver_close(d.driver) < 0
        Aeron.throwerror()
    end
end

Base.cconvert(::Type{Ptr{aeron_driver_t}}, d::Driver) = d
Base.unsafe_convert(::Type{Ptr{aeron_driver_t}}, d::Driver) = d.driver

"""
    aeron_dir(d)

Get the directory used for the media driver for `Driver`.

# Arguments
- `d`: The `Driver` object.

# Returns
- The directory name of the Aeron media driver context.
"""
function aeron_dir(d::Driver)
    aeron_dir(context(d))
end

function start(d::Driver, manual_main_loop::Bool=false)
    if aeron_driver_start(d.driver, manual_main_loop) < 0
        Aeron.throwerror()
    end
end

function do_work(d::Driver)
    if aeron_driver_main_do_work(d.driver) < 0
        Aeron.throwerror()
    end
end

function main_idle_strategy(d::Driver, work_count::Int)
    if aeron_driver_main_idle_strategy(d.driver, work_count) < 0
        Aeron.throwerror()
    end
end

context(d::Driver) = d.context

function launch(c::Context)
    driver = Driver(c)
    start(driver)

    return driver
end

function launch(f::Function, c::Context)
    driver = launch(c)
    try
        f(driver)
    finally
        close(driver)
    end
end

function launch(f::Function)
    Context() do context
        driver = launch(context)
        try
            f(driver)
        finally
            close(driver)
        end
    end
end

function launch_embedded(c::Context)
    dir = "$(aeron_dir(c))-$(UUIDs.uuid4())"
    aeron_dir!(c, dir)
    dir_delete_on_start!(c, true)
    dir_delete_on_shutdown!(c, true)

    launch(c)
end

function launch_embedded(f::Function, c::Context)
    driver = launch_embedded(c)
    try
        f(driver)
    finally
        close(driver)
    end
end

function launch_embedded(f::Function)
    Context() do context
        driver = launch_embedded(context)
        try
            f(driver)
        finally
            close(driver)
        end
    end
end

end # module MediaDriver
