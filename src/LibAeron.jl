module LibAeron

using Aeron_jll
export Aeron_jll

using CEnum

# Prologue file

const INT64_C = Int64
const INT64_MAX = typemax(INT64_C)

# End of prologue file

mutable struct aeron_context_stct end

const aeron_context_t = aeron_context_stct

mutable struct aeron_stct end

const aeron_t = aeron_stct

"""
    aeron_buffer_claim_stct

Structure used to hold information for a try\\_claim function call.
"""
struct aeron_buffer_claim_stct
    frame_header::Ptr{UInt8}
    data::Ptr{UInt8}
    length::Csize_t
end

"""
Structure used to hold information for a try\\_claim function call.
"""
const aeron_buffer_claim_t = aeron_buffer_claim_stct

mutable struct aeron_publication_stct end

const aeron_publication_t = aeron_publication_stct

mutable struct aeron_exclusive_publication_stct end

const aeron_exclusive_publication_t = aeron_exclusive_publication_stct

mutable struct aeron_header_stct end

const aeron_header_t = aeron_header_stct

struct aeron_header_values_frame_stct
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{aeron_header_values_frame_stct}, f::Symbol)
    f === :frame_length && return Ptr{Int32}(x + 0)
    f === :version && return Ptr{Int8}(x + 4)
    f === :flags && return Ptr{UInt8}(x + 5)
    f === :type && return Ptr{Int16}(x + 6)
    f === :term_offset && return Ptr{Int32}(x + 8)
    f === :session_id && return Ptr{Int32}(x + 12)
    f === :stream_id && return Ptr{Int32}(x + 16)
    f === :term_id && return Ptr{Int32}(x + 20)
    f === :reserved_value && return Ptr{Int64}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::aeron_header_values_frame_stct, f::Symbol)
    r = Ref{aeron_header_values_frame_stct}(x)
    ptr = Base.unsafe_convert(Ptr{aeron_header_values_frame_stct}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{aeron_header_values_frame_stct}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const aeron_header_values_frame_t = aeron_header_values_frame_stct

struct aeron_header_values_stct
    data::NTuple{44, UInt8}
end

function Base.getproperty(x::Ptr{aeron_header_values_stct}, f::Symbol)
    f === :frame && return Ptr{aeron_header_values_frame_t}(x + 0)
    f === :initial_term_id && return Ptr{Int32}(x + 32)
    f === :position_bits_to_shift && return Ptr{Csize_t}(x + 36)
    return getfield(x, f)
end

function Base.getproperty(x::aeron_header_values_stct, f::Symbol)
    r = Ref{aeron_header_values_stct}(x)
    ptr = Base.unsafe_convert(Ptr{aeron_header_values_stct}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{aeron_header_values_stct}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const aeron_header_values_t = aeron_header_values_stct

mutable struct aeron_subscription_stct end

const aeron_subscription_t = aeron_subscription_stct

mutable struct aeron_image_stct end

const aeron_image_t = aeron_image_stct

mutable struct aeron_counter_stct end

const aeron_counter_t = aeron_counter_stct

mutable struct aeron_log_buffer_stct end

const aeron_log_buffer_t = aeron_log_buffer_stct

mutable struct aeron_counters_reader_stct end

const aeron_counters_reader_t = aeron_counters_reader_stct

mutable struct aeron_client_registering_resource_stct end

const aeron_async_add_publication_t = aeron_client_registering_resource_stct

const aeron_async_add_exclusive_publication_t = aeron_client_registering_resource_stct

const aeron_async_add_subscription_t = aeron_client_registering_resource_stct

const aeron_async_add_counter_t = aeron_client_registering_resource_stct

const aeron_async_destination_t = aeron_client_registering_resource_stct

const aeron_async_destination_by_id_t = aeron_client_registering_resource_stct

mutable struct aeron_image_fragment_assembler_stct end

const aeron_image_fragment_assembler_t = aeron_image_fragment_assembler_stct

mutable struct aeron_image_controlled_fragment_assembler_stct end

const aeron_image_controlled_fragment_assembler_t = aeron_image_controlled_fragment_assembler_stct

mutable struct aeron_fragment_assembler_stct end

const aeron_fragment_assembler_t = aeron_fragment_assembler_stct

mutable struct aeron_controlled_fragment_assembler_stct end

const aeron_controlled_fragment_assembler_t = aeron_controlled_fragment_assembler_stct

"""
    aeron_context_set_dir(context, value)

### Prototype
```c
int aeron_context_set_dir(aeron_context_t *context, const char *value);
```
"""
function aeron_context_set_dir(context, value)
    @ccall libaeron.aeron_context_set_dir(context::Ptr{aeron_context_t}, value::Cstring)::Cint
end

"""
    aeron_context_get_dir(context)

### Prototype
```c
const char *aeron_context_get_dir(aeron_context_t *context);
```
"""
function aeron_context_get_dir(context)
    @ccall libaeron.aeron_context_get_dir(context::Ptr{aeron_context_t})::Cstring
end

"""
    aeron_context_set_driver_timeout_ms(context, value)

### Prototype
```c
int aeron_context_set_driver_timeout_ms(aeron_context_t *context, uint64_t value);
```
"""
function aeron_context_set_driver_timeout_ms(context, value)
    @ccall libaeron.aeron_context_set_driver_timeout_ms(context::Ptr{aeron_context_t}, value::UInt64)::Cint
end

"""
    aeron_context_get_driver_timeout_ms(context)

### Prototype
```c
uint64_t aeron_context_get_driver_timeout_ms(aeron_context_t *context);
```
"""
function aeron_context_get_driver_timeout_ms(context)
    @ccall libaeron.aeron_context_get_driver_timeout_ms(context::Ptr{aeron_context_t})::UInt64
end

"""
    aeron_context_set_keepalive_interval_ns(context, value)

### Prototype
```c
int aeron_context_set_keepalive_interval_ns(aeron_context_t *context, uint64_t value);
```
"""
function aeron_context_set_keepalive_interval_ns(context, value)
    @ccall libaeron.aeron_context_set_keepalive_interval_ns(context::Ptr{aeron_context_t}, value::UInt64)::Cint
end

"""
    aeron_context_get_keepalive_interval_ns(context)

### Prototype
```c
uint64_t aeron_context_get_keepalive_interval_ns(aeron_context_t *context);
```
"""
function aeron_context_get_keepalive_interval_ns(context)
    @ccall libaeron.aeron_context_get_keepalive_interval_ns(context::Ptr{aeron_context_t})::UInt64
end

"""
    aeron_context_set_resource_linger_duration_ns(context, value)

### Prototype
```c
int aeron_context_set_resource_linger_duration_ns(aeron_context_t *context, uint64_t value);
```
"""
function aeron_context_set_resource_linger_duration_ns(context, value)
    @ccall libaeron.aeron_context_set_resource_linger_duration_ns(context::Ptr{aeron_context_t}, value::UInt64)::Cint
end

"""
    aeron_context_get_resource_linger_duration_ns(context)

### Prototype
```c
uint64_t aeron_context_get_resource_linger_duration_ns(aeron_context_t *context);
```
"""
function aeron_context_get_resource_linger_duration_ns(context)
    @ccall libaeron.aeron_context_get_resource_linger_duration_ns(context::Ptr{aeron_context_t})::UInt64
end

"""
    aeron_context_get_idle_sleep_duration_ns(context)

### Prototype
```c
uint64_t aeron_context_get_idle_sleep_duration_ns(aeron_context_t *context);
```
"""
function aeron_context_get_idle_sleep_duration_ns(context)
    @ccall libaeron.aeron_context_get_idle_sleep_duration_ns(context::Ptr{aeron_context_t})::UInt64
end

"""
    aeron_context_set_idle_sleep_duration_ns(context, value)

### Prototype
```c
int aeron_context_set_idle_sleep_duration_ns(aeron_context_t *context, uint64_t value);
```
"""
function aeron_context_set_idle_sleep_duration_ns(context, value)
    @ccall libaeron.aeron_context_set_idle_sleep_duration_ns(context::Ptr{aeron_context_t}, value::UInt64)::Cint
end

"""
    aeron_context_set_pre_touch_mapped_memory(context, value)

### Prototype
```c
int aeron_context_set_pre_touch_mapped_memory(aeron_context_t *context, bool value);
```
"""
function aeron_context_set_pre_touch_mapped_memory(context, value)
    @ccall libaeron.aeron_context_set_pre_touch_mapped_memory(context::Ptr{aeron_context_t}, value::Bool)::Cint
end

"""
    aeron_context_get_pre_touch_mapped_memory(context)

### Prototype
```c
bool aeron_context_get_pre_touch_mapped_memory(aeron_context_t *context);
```
"""
function aeron_context_get_pre_touch_mapped_memory(context)
    @ccall libaeron.aeron_context_get_pre_touch_mapped_memory(context::Ptr{aeron_context_t})::Bool
end

"""
    aeron_context_set_client_name(context, value)

### Prototype
```c
int aeron_context_set_client_name(aeron_context_t *context, const char *value);
```
"""
function aeron_context_set_client_name(context, value)
    @ccall libaeron.aeron_context_set_client_name(context::Ptr{aeron_context_t}, value::Cstring)::Cint
end

"""
    aeron_context_get_client_name(context)

### Prototype
```c
const char *aeron_context_get_client_name(aeron_context_t *context);
```
"""
function aeron_context_get_client_name(context)
    @ccall libaeron.aeron_context_get_client_name(context::Ptr{aeron_context_t})::Cstring
end

# typedef void ( * aeron_error_handler_t ) ( void * clientd , int errcode , const char * message )
"""
The error handler to be called when an error occurs.
"""
const aeron_error_handler_t = Ptr{Cvoid}

# typedef void ( * aeron_notification_t ) ( void * clientd )
"""
Generalised notification callback.
"""
const aeron_notification_t = Ptr{Cvoid}

"""
    aeron_context_set_error_handler(context, handler, clientd)

### Prototype
```c
int aeron_context_set_error_handler(aeron_context_t *context, aeron_error_handler_t handler, void *clientd);
```
"""
function aeron_context_set_error_handler(context, handler, clientd)
    @ccall libaeron.aeron_context_set_error_handler(context::Ptr{aeron_context_t}, handler::aeron_error_handler_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_error_handler(context)

### Prototype
```c
aeron_error_handler_t aeron_context_get_error_handler(aeron_context_t *context);
```
"""
function aeron_context_get_error_handler(context)
    @ccall libaeron.aeron_context_get_error_handler(context::Ptr{aeron_context_t})::aeron_error_handler_t
end

"""
    aeron_context_get_error_handler_clientd(context)

### Prototype
```c
void *aeron_context_get_error_handler_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_error_handler_clientd(context)
    @ccall libaeron.aeron_context_get_error_handler_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

# typedef void ( * aeron_on_new_publication_t ) ( void * clientd , aeron_async_add_publication_t * async , const char * channel , int32_t stream_id , int32_t session_id , int64_t correlation_id )
"""
Function called by aeron\\_client\\_t to deliver notification that the media driver has added an [`aeron_publication_t`](@ref) or [`aeron_exclusive_publication_t`](@ref) successfully.

Implementations should do the minimum work for passing off state to another thread for later processing.

# Arguments
* `clientd`: to be returned in the call
* `async`: associated with the original add publication call
* `channel`: of the publication
* `stream_id`: within the channel of the publication
* `session_id`: of the publication
* `correlation_id`: used by the publication
"""
const aeron_on_new_publication_t = Ptr{Cvoid}

"""
    aeron_context_set_on_new_publication(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_new_publication(aeron_context_t *context, aeron_on_new_publication_t handler, void *clientd);
```
"""
function aeron_context_set_on_new_publication(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_new_publication(context::Ptr{aeron_context_t}, handler::aeron_on_new_publication_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_new_publication(context)

### Prototype
```c
aeron_on_new_publication_t aeron_context_get_on_new_publication(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_publication(context)
    @ccall libaeron.aeron_context_get_on_new_publication(context::Ptr{aeron_context_t})::aeron_on_new_publication_t
end

"""
    aeron_context_get_on_new_publication_clientd(context)

### Prototype
```c
void *aeron_context_get_on_new_publication_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_publication_clientd(context)
    @ccall libaeron.aeron_context_get_on_new_publication_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

"""
    aeron_context_set_on_new_exclusive_publication(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_new_exclusive_publication( aeron_context_t *context, aeron_on_new_publication_t handler, void *clientd);
```
"""
function aeron_context_set_on_new_exclusive_publication(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_new_exclusive_publication(context::Ptr{aeron_context_t}, handler::aeron_on_new_publication_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_new_exclusive_publication(context)

### Prototype
```c
aeron_on_new_publication_t aeron_context_get_on_new_exclusive_publication(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_exclusive_publication(context)
    @ccall libaeron.aeron_context_get_on_new_exclusive_publication(context::Ptr{aeron_context_t})::aeron_on_new_publication_t
end

"""
    aeron_context_get_on_new_exclusive_publication_clientd(context)

### Prototype
```c
void *aeron_context_get_on_new_exclusive_publication_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_exclusive_publication_clientd(context)
    @ccall libaeron.aeron_context_get_on_new_exclusive_publication_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

# typedef void ( * aeron_on_new_subscription_t ) ( void * clientd , aeron_async_add_subscription_t * async , const char * channel , int32_t stream_id , int64_t correlation_id )
"""
Function called by aeron\\_client\\_t to deliver notification that the media driver has added an [`aeron_subscription_t`](@ref) successfully.

Implementations should do the minimum work for handing off state to another thread for later processing.

# Arguments
* `clientd`: to be returned in the call
* `async`: associated with the original aeron\\_add\\_async\\_subscription call
* `channel`: of the subscription
* `stream_id`: within the channel of the subscription
* `session_id`: of the subscription
* `correlation_id`: used by the subscription
"""
const aeron_on_new_subscription_t = Ptr{Cvoid}

"""
    aeron_context_set_on_new_subscription(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_new_subscription( aeron_context_t *context, aeron_on_new_subscription_t handler, void *clientd);
```
"""
function aeron_context_set_on_new_subscription(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_new_subscription(context::Ptr{aeron_context_t}, handler::aeron_on_new_subscription_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_new_subscription(context)

### Prototype
```c
aeron_on_new_subscription_t aeron_context_get_on_new_subscription(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_subscription(context)
    @ccall libaeron.aeron_context_get_on_new_subscription(context::Ptr{aeron_context_t})::aeron_on_new_subscription_t
end

"""
    aeron_context_get_on_new_subscription_clientd(context)

### Prototype
```c
void *aeron_context_get_on_new_subscription_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_new_subscription_clientd(context)
    @ccall libaeron.aeron_context_get_on_new_subscription_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

# typedef void ( * aeron_on_available_image_t ) ( void * clientd , aeron_subscription_t * subscription , aeron_image_t * image )
"""
Function called by aeron\\_client\\_t to deliver notifications that an [`aeron_image_t`](@ref) was added.

# Arguments
* `clientd`: to be returned in the call.
* `subscription`: that image is part of.
* `image`: that has become available.
"""
const aeron_on_available_image_t = Ptr{Cvoid}

# typedef void ( * aeron_on_unavailable_image_t ) ( void * clientd , aeron_subscription_t * subscription , aeron_image_t * image )
"""
Function called by aeron\\_client\\_t to deliver notifications that an [`aeron_image_t`](@ref) has been removed from use and should not be used any longer.

# Arguments
* `clientd`: to be returned in the call.
* `subscription`: that image is part of.
* `image`: that has become unavailable.
"""
const aeron_on_unavailable_image_t = Ptr{Cvoid}

# typedef void ( * aeron_on_available_counter_t ) ( void * clientd , aeron_counters_reader_t * counters_reader , int64_t registration_id , int32_t counter_id )
"""
Function called by aeron\\_client\\_t to deliver notifications that a counter has been added to the driver.

# Arguments
* `clientd`: to be returned in the call.
* `counters_reader`: that holds the counter.
* `registration_id`: of the counter.
* `counter_id`: of the counter.
"""
const aeron_on_available_counter_t = Ptr{Cvoid}

"""
    aeron_context_set_on_available_counter(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_available_counter( aeron_context_t *context, aeron_on_available_counter_t handler, void *clientd);
```
"""
function aeron_context_set_on_available_counter(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_available_counter(context::Ptr{aeron_context_t}, handler::aeron_on_available_counter_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_available_counter(context)

### Prototype
```c
aeron_on_available_counter_t aeron_context_get_on_available_counter(aeron_context_t *context);
```
"""
function aeron_context_get_on_available_counter(context)
    @ccall libaeron.aeron_context_get_on_available_counter(context::Ptr{aeron_context_t})::aeron_on_available_counter_t
end

"""
    aeron_context_get_on_available_counter_clientd(context)

### Prototype
```c
void *aeron_context_get_on_available_counter_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_available_counter_clientd(context)
    @ccall libaeron.aeron_context_get_on_available_counter_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

# typedef void ( * aeron_on_unavailable_counter_t ) ( void * clientd , aeron_counters_reader_t * counters_reader , int64_t registration_id , int32_t counter_id )
"""
Function called by aeron\\_client\\_t to deliver notifications that a counter has been removed from the driver.

# Arguments
* `clientd`: to be returned in the call.
* `counters_reader`: that holds the counter.
* `registration_id`: of the counter.
* `counter_id`: of the counter.
"""
const aeron_on_unavailable_counter_t = Ptr{Cvoid}

"""
    aeron_context_set_on_unavailable_counter(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_unavailable_counter( aeron_context_t *context, aeron_on_unavailable_counter_t handler, void *clientd);
```
"""
function aeron_context_set_on_unavailable_counter(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_unavailable_counter(context::Ptr{aeron_context_t}, handler::aeron_on_unavailable_counter_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_unavailable_counter(context)

### Prototype
```c
aeron_on_unavailable_counter_t aeron_context_get_on_unavailable_counter(aeron_context_t *context);
```
"""
function aeron_context_get_on_unavailable_counter(context)
    @ccall libaeron.aeron_context_get_on_unavailable_counter(context::Ptr{aeron_context_t})::aeron_on_unavailable_counter_t
end

"""
    aeron_context_get_on_unavailable_counter_clientd(context)

### Prototype
```c
void *aeron_context_get_on_unavailable_counter_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_unavailable_counter_clientd(context)
    @ccall libaeron.aeron_context_get_on_unavailable_counter_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

# typedef void ( * aeron_on_close_client_t ) ( void * clientd )
"""
Function called by aeron\\_client\\_t to deliver notifications that the client is closing.

# Arguments
* `clientd`: to be returned in the call.
"""
const aeron_on_close_client_t = Ptr{Cvoid}

"""
    aeron_context_set_on_close_client(context, handler, clientd)

### Prototype
```c
int aeron_context_set_on_close_client( aeron_context_t *context, aeron_on_close_client_t handler, void *clientd);
```
"""
function aeron_context_set_on_close_client(context, handler, clientd)
    @ccall libaeron.aeron_context_set_on_close_client(context::Ptr{aeron_context_t}, handler::aeron_on_close_client_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_on_close_client(context)

### Prototype
```c
aeron_on_close_client_t aeron_context_get_on_close_client(aeron_context_t *context);
```
"""
function aeron_context_get_on_close_client(context)
    @ccall libaeron.aeron_context_get_on_close_client(context::Ptr{aeron_context_t})::aeron_on_close_client_t
end

"""
    aeron_context_get_on_close_client_clientd(context)

### Prototype
```c
void *aeron_context_get_on_close_client_clientd(aeron_context_t *context);
```
"""
function aeron_context_get_on_close_client_clientd(context)
    @ccall libaeron.aeron_context_get_on_close_client_clientd(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

"""
    aeron_context_set_use_conductor_agent_invoker(context, value)

Whether to use an invoker to control the conductor agent or spawn a thread.

### Prototype
```c
int aeron_context_set_use_conductor_agent_invoker(aeron_context_t *context, bool value);
```
"""
function aeron_context_set_use_conductor_agent_invoker(context, value)
    @ccall libaeron.aeron_context_set_use_conductor_agent_invoker(context::Ptr{aeron_context_t}, value::Bool)::Cint
end

"""
    aeron_context_get_use_conductor_agent_invoker(context)

### Prototype
```c
bool aeron_context_get_use_conductor_agent_invoker(aeron_context_t *context);
```
"""
function aeron_context_get_use_conductor_agent_invoker(context)
    @ccall libaeron.aeron_context_get_use_conductor_agent_invoker(context::Ptr{aeron_context_t})::Bool
end

# typedef void ( * aeron_agent_on_start_func_t ) ( void * state , const char * role_name )
const aeron_agent_on_start_func_t = Ptr{Cvoid}

"""
    aeron_context_set_agent_on_start_function(context, value, state)

### Prototype
```c
int aeron_context_set_agent_on_start_function( aeron_context_t *context, aeron_agent_on_start_func_t value, void *state);
```
"""
function aeron_context_set_agent_on_start_function(context, value, state)
    @ccall libaeron.aeron_context_set_agent_on_start_function(context::Ptr{aeron_context_t}, value::aeron_agent_on_start_func_t, state::Ptr{Cvoid})::Cint
end

"""
    aeron_context_get_agent_on_start_function(context)

### Prototype
```c
aeron_agent_on_start_func_t aeron_context_get_agent_on_start_function(aeron_context_t *context);
```
"""
function aeron_context_get_agent_on_start_function(context)
    @ccall libaeron.aeron_context_get_agent_on_start_function(context::Ptr{aeron_context_t})::aeron_agent_on_start_func_t
end

"""
    aeron_context_get_agent_on_start_state(context)

### Prototype
```c
void *aeron_context_get_agent_on_start_state(aeron_context_t *context);
```
"""
function aeron_context_get_agent_on_start_state(context)
    @ccall libaeron.aeron_context_get_agent_on_start_state(context::Ptr{aeron_context_t})::Ptr{Cvoid}
end

"""
    aeron_context_init(context)

Create a [`aeron_context_t`](@ref) struct and initialize with default values.

# Arguments
* `context`: to create and initialize
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_context_init(aeron_context_t **context);
```
"""
function aeron_context_init(context)
    @ccall libaeron.aeron_context_init(context::Ptr{Ptr{aeron_context_t}})::Cint
end

"""
    aeron_context_close(context)

Close and delete [`aeron_context_t`](@ref) struct.

# Arguments
* `context`: to close and delete
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_context_close(aeron_context_t *context);
```
"""
function aeron_context_close(context)
    @ccall libaeron.aeron_context_close(context::Ptr{aeron_context_t})::Cint
end

"""
    aeron_init(client, context)

Create a [`aeron_t`](@ref) client struct and initialize from the [`aeron_context_t`](@ref) struct.

The given [`aeron_context_t`](@ref) struct will be used exclusively by the client. Do not reuse between clients.

# Arguments
* `aeron`: client to create and initialize.
* `context`: to use for initialization.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_init(aeron_t **client, aeron_context_t *context);
```
"""
function aeron_init(client, context)
    @ccall libaeron.aeron_init(client::Ptr{Ptr{aeron_t}}, context::Ptr{aeron_context_t})::Cint
end

"""
    aeron_start(client)

Start an [`aeron_t`](@ref). This may spawn a thread for the Client Conductor.

# Arguments
* `client`: to start.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_start(aeron_t *client);
```
"""
function aeron_start(client)
    @ccall libaeron.aeron_start(client::Ptr{aeron_t})::Cint
end

"""
    aeron_main_do_work(client)

Call the Conductor main do\\_work duty cycle once.

Client must have been created with use conductor invoker set to true.

# Arguments
* `client`: to call do\\_work duty cycle on.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_main_do_work(aeron_t *client);
```
"""
function aeron_main_do_work(client)
    @ccall libaeron.aeron_main_do_work(client::Ptr{aeron_t})::Cint
end

"""
    aeron_main_idle_strategy(client, work_count)

Call the Conductor Idle Strategy.

# Arguments
* `client`: to idle.
* `work_count`: to pass to idle strategy.
### Prototype
```c
void aeron_main_idle_strategy(aeron_t *client, int work_count);
```
"""
function aeron_main_idle_strategy(client, work_count)
    @ccall libaeron.aeron_main_idle_strategy(client::Ptr{aeron_t}, work_count::Cint)::Cvoid
end

"""
    aeron_close(client)

Close and delete [`aeron_t`](@ref) struct.

# Arguments
* `client`: to close and delete
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_close(aeron_t *client);
```
"""
function aeron_close(client)
    @ccall libaeron.aeron_close(client::Ptr{aeron_t})::Cint
end

"""
    aeron_is_closed(client)

Determines if the client has been closed, e.g. via a driver timeout. Don't call this method after calling [`aeron_close`](@ref) as that will have already freed the associated memory.

# Arguments
* `client`: to check if closed.
# Returns
true if it has been closed, false otherwise.
### Prototype
```c
bool aeron_is_closed(aeron_t *client);
```
"""
function aeron_is_closed(client)
    @ccall libaeron.aeron_is_closed(client::Ptr{aeron_t})::Bool
end

"""
    aeron_print_counters(client, stream_out)

Call stream\\_out to print the counter labels and values.

# Arguments
* `client`: to get the counters from.
* `stream_out`: to call for each label and value.
### Prototype
```c
void aeron_print_counters(aeron_t *client, void (*stream_out)(const char *));
```
"""
function aeron_print_counters(client, stream_out)
    @ccall libaeron.aeron_print_counters(client::Ptr{aeron_t}, stream_out::Ptr{Cvoid})::Cvoid
end

"""
    aeron_context(client)

Return the [`aeron_context_t`](@ref) that is in use by the given client.

# Arguments
* `client`: to return the [`aeron_context_t`](@ref) for.
# Returns
the [`aeron_context_t`](@ref) for the given client or NULL for an error.
### Prototype
```c
aeron_context_t *aeron_context(aeron_t *client);
```
"""
function aeron_context(client)
    @ccall libaeron.aeron_context(client::Ptr{aeron_t})::Ptr{aeron_context_t}
end

"""
    aeron_client_id(client)

Return the client id in use by the client.

# Arguments
* `client`: to return the client id for.
# Returns
id value or -1 for an error.
### Prototype
```c
int64_t aeron_client_id(aeron_t *client);
```
"""
function aeron_client_id(client)
    @ccall libaeron.aeron_client_id(client::Ptr{aeron_t})::Int64
end

"""
    aeron_next_correlation_id(client)

Return a unique correlation id from the driver.

# Arguments
* `client`: to use to get the id.
# Returns
unique correlation id or -1 for an error.
### Prototype
```c
int64_t aeron_next_correlation_id(aeron_t *client);
```
"""
function aeron_next_correlation_id(client)
    @ccall libaeron.aeron_next_correlation_id(client::Ptr{aeron_t})::Int64
end

"""
    aeron_async_add_publication(async, client, uri, stream_id)

Asynchronously add a publication using the given client and return an object to use to determine when the publication is available.

# Arguments
* `async`: object to use for polling completion.
* `client`: to add the publication to.
* `uri`: for the channel of the publication.
* `stream_id`: for the publication.
# Returns
0 for success or -1 for an error.
### Prototype
```c
int aeron_async_add_publication( aeron_async_add_publication_t **async, aeron_t *client, const char *uri, int32_t stream_id);
```
"""
function aeron_async_add_publication(async, client, uri, stream_id)
    @ccall libaeron.aeron_async_add_publication(async::Ptr{Ptr{aeron_async_add_publication_t}}, client::Ptr{aeron_t}, uri::Cstring, stream_id::Int32)::Cint
end

"""
    aeron_async_add_publication_poll(publication, async)

Poll the completion of the [`aeron_async_add_publication`](@ref) call.

# Arguments
* `publication`: to set if completed successfully.
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_async_add_publication_poll(aeron_publication_t **publication, aeron_async_add_publication_t *async);
```
"""
function aeron_async_add_publication_poll(publication, async)
    @ccall libaeron.aeron_async_add_publication_poll(publication::Ptr{Ptr{aeron_publication_t}}, async::Ptr{aeron_async_add_publication_t})::Cint
end

"""
    aeron_async_add_exclusive_publication(async, client, uri, stream_id)

Asynchronously add an exclusive publication using the given client and return an object to use to determine when the publication is available.

# Arguments
* `async`: object to use for polling completion.
* `client`: to add the publication to.
* `uri`: for the channel of the publication.
* `stream_id`: for the publication.
# Returns
0 for success or -1 for an error.
### Prototype
```c
int aeron_async_add_exclusive_publication( aeron_async_add_exclusive_publication_t **async, aeron_t *client, const char *uri, int32_t stream_id);
```
"""
function aeron_async_add_exclusive_publication(async, client, uri, stream_id)
    @ccall libaeron.aeron_async_add_exclusive_publication(async::Ptr{Ptr{aeron_async_add_exclusive_publication_t}}, client::Ptr{aeron_t}, uri::Cstring, stream_id::Int32)::Cint
end

"""
    aeron_async_add_exclusive_publication_poll(publication, async)

Poll the completion of the [`aeron_async_add_exclusive_publication`](@ref) call.

# Arguments
* `publication`: to set if completed successfully.
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_async_add_exclusive_publication_poll( aeron_exclusive_publication_t **publication, aeron_async_add_exclusive_publication_t *async);
```
"""
function aeron_async_add_exclusive_publication_poll(publication, async)
    @ccall libaeron.aeron_async_add_exclusive_publication_poll(publication::Ptr{Ptr{aeron_exclusive_publication_t}}, async::Ptr{aeron_async_add_exclusive_publication_t})::Cint
end

"""
    aeron_async_add_subscription(async, client, uri, stream_id, on_available_image_handler, on_available_image_clientd, on_unavailable_image_handler, on_unavailable_image_clientd)

Asynchronously add a subscription using the given client and return an object to use to determine when the subscription is available.

# Arguments
* `async`: object to use for polling completion.
* `client`: to add the subscription to.
* `uri`: for the channel of the subscription.
* `stream_id`: for the subscription.
* `on_available_image_handler`: to be called when images become available on the subscription.
* `on_available_image_clientd`: to be passed when images become available on the subscription.
* `on_unavailable_image_handler`: to be called when images go unavailable on the subscription.
* `on_unavailable_image_clientd`: to be passed when images go unavailable on the subscription.
# Returns
0 for success or -1 for an error.
### Prototype
```c
int aeron_async_add_subscription( aeron_async_add_subscription_t **async, aeron_t *client, const char *uri, int32_t stream_id, aeron_on_available_image_t on_available_image_handler, void *on_available_image_clientd, aeron_on_unavailable_image_t on_unavailable_image_handler, void *on_unavailable_image_clientd);
```
"""
function aeron_async_add_subscription(async, client, uri, stream_id, on_available_image_handler, on_available_image_clientd, on_unavailable_image_handler, on_unavailable_image_clientd)
    @ccall libaeron.aeron_async_add_subscription(async::Ptr{Ptr{aeron_async_add_subscription_t}}, client::Ptr{aeron_t}, uri::Cstring, stream_id::Int32, on_available_image_handler::aeron_on_available_image_t, on_available_image_clientd::Ptr{Cvoid}, on_unavailable_image_handler::aeron_on_unavailable_image_t, on_unavailable_image_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_async_add_subscription_poll(subscription, async)

Poll the completion of the [`aeron_async_add_subscription`](@ref) call.

# Arguments
* `subscription`: to set if completed successfully.
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_async_add_subscription_poll(aeron_subscription_t **subscription, aeron_async_add_subscription_t *async);
```
"""
function aeron_async_add_subscription_poll(subscription, async)
    @ccall libaeron.aeron_async_add_subscription_poll(subscription::Ptr{Ptr{aeron_subscription_t}}, async::Ptr{aeron_async_add_subscription_t})::Cint
end

"""
    aeron_counters_reader(client)

Return a reference to the counters reader of the given client.

The [`aeron_counters_reader_t`](@ref) is maintained by the client. And should not be freed.

# Arguments
* `client`: that contains the counters reader.
# Returns
[`aeron_counters_reader_t`](@ref) or NULL for error.
### Prototype
```c
aeron_counters_reader_t *aeron_counters_reader(aeron_t *client);
```
"""
function aeron_counters_reader(client)
    @ccall libaeron.aeron_counters_reader(client::Ptr{aeron_t})::Ptr{aeron_counters_reader_t}
end

"""
    aeron_async_add_counter(async, client, type_id, key_buffer, key_buffer_length, label_buffer, label_buffer_length)

Asynchronously add a counter using the given client and return an object to use to determine when the counter is available.

# Arguments
* `async`: object to use for polling completion.
* `client`: to add the counter to.
* `type_id`: for the counter.
* `key_buffer`: for the counter.
* `key_buffer_length`: for the counter.
* `label_buffer`: for the counter.
* `label_buffer_length`: for the counter.
# Returns
0 for success or -1 for an error.
### Prototype
```c
int aeron_async_add_counter( aeron_async_add_counter_t **async, aeron_t *client, int32_t type_id, const uint8_t *key_buffer, size_t key_buffer_length, const char *label_buffer, size_t label_buffer_length);
```
"""
function aeron_async_add_counter(async, client, type_id, key_buffer, key_buffer_length, label_buffer, label_buffer_length)
    @ccall libaeron.aeron_async_add_counter(async::Ptr{Ptr{aeron_async_add_counter_t}}, client::Ptr{aeron_t}, type_id::Int32, key_buffer::Ptr{UInt8}, key_buffer_length::Csize_t, label_buffer::Cstring, label_buffer_length::Csize_t)::Cint
end

"""
    aeron_async_add_counter_poll(counter, async)

Poll the completion of the <code>[`aeron_async_add_counter`](@ref)</code> or <code>[`aeron_async_add_static_counter`](@ref)</code> calls.

# Arguments
* `counter`: to set if completed successfully.
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_async_add_counter_poll(aeron_counter_t **counter, aeron_async_add_counter_t *async);
```
"""
function aeron_async_add_counter_poll(counter, async)
    @ccall libaeron.aeron_async_add_counter_poll(counter::Ptr{Ptr{aeron_counter_t}}, async::Ptr{aeron_async_add_counter_t})::Cint
end

"""
    aeron_async_add_static_counter(async, client, type_id, key_buffer, key_buffer_length, label_buffer, label_buffer_length, registration_id)

Asynchronously allocates or returns an existing static counter instance using specified <code>type\\_id</code> and <code>registration\\_id</code>. Such counter cannot be deleted and its lifecycle is decoupled from the client that created it. Returns an object to use to determine when the counter is available.

# Arguments
* `async`: object to use for polling completion.
* `client`: to add the counter to.
* `type_id`: for the counter.
* `key_buffer`: for the counter.
* `key_buffer_length`: for the counter.
* `label_buffer`: for the counter.
* `label_buffer_length`: for the counter.
* `registration_id`: that uniquely identifies the counter.
# Returns
0 for success or -1 for an error.
### Prototype
```c
int aeron_async_add_static_counter( aeron_async_add_counter_t **async, aeron_t *client, int32_t type_id, const uint8_t *key_buffer, size_t key_buffer_length, const char *label_buffer, size_t label_buffer_length, int64_t registration_id);
```
"""
function aeron_async_add_static_counter(async, client, type_id, key_buffer, key_buffer_length, label_buffer, label_buffer_length, registration_id)
    @ccall libaeron.aeron_async_add_static_counter(async::Ptr{Ptr{aeron_async_add_counter_t}}, client::Ptr{aeron_t}, type_id::Int32, key_buffer::Ptr{UInt8}, key_buffer_length::Csize_t, label_buffer::Cstring, label_buffer_length::Csize_t, registration_id::Int64)::Cint
end

struct aeron_on_available_counter_pair_stct
    handler::aeron_on_available_counter_t
    clientd::Ptr{Cvoid}
end

const aeron_on_available_counter_pair_t = aeron_on_available_counter_pair_stct

struct aeron_on_unavailable_counter_pair_stct
    handler::aeron_on_unavailable_counter_t
    clientd::Ptr{Cvoid}
end

const aeron_on_unavailable_counter_pair_t = aeron_on_unavailable_counter_pair_stct

struct aeron_on_close_client_pair_stct
    handler::aeron_on_close_client_t
    clientd::Ptr{Cvoid}
end

const aeron_on_close_client_pair_t = aeron_on_close_client_pair_stct

"""
    aeron_add_available_counter_handler(client, pair)

Add a handler to be called when a new counter becomes available.

NOTE: This function blocks until the handler is added by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_add_available_counter_handler(aeron_t *client, aeron_on_available_counter_pair_t *pair);
```
"""
function aeron_add_available_counter_handler(client, pair)
    @ccall libaeron.aeron_add_available_counter_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_available_counter_pair_t})::Cint
end

"""
    aeron_remove_available_counter_handler(client, pair)

Remove a previously added handler to be called when a new counter becomes available.

NOTE: This function blocks until the handler is removed by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_remove_available_counter_handler(aeron_t *client, aeron_on_available_counter_pair_t *pair);
```
"""
function aeron_remove_available_counter_handler(client, pair)
    @ccall libaeron.aeron_remove_available_counter_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_available_counter_pair_t})::Cint
end

"""
    aeron_add_unavailable_counter_handler(client, pair)

Add a handler to be called when a new counter becomes unavailable or goes away.

NOTE: This function blocks until the handler is added by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_add_unavailable_counter_handler(aeron_t *client, aeron_on_unavailable_counter_pair_t *pair);
```
"""
function aeron_add_unavailable_counter_handler(client, pair)
    @ccall libaeron.aeron_add_unavailable_counter_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_unavailable_counter_pair_t})::Cint
end

"""
    aeron_remove_unavailable_counter_handler(client, pair)

Remove a previously added handler to be called when a new counter becomes unavailable or goes away.

NOTE: This function blocks until the handler is removed by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_remove_unavailable_counter_handler(aeron_t *client, aeron_on_unavailable_counter_pair_t *pair);
```
"""
function aeron_remove_unavailable_counter_handler(client, pair)
    @ccall libaeron.aeron_remove_unavailable_counter_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_unavailable_counter_pair_t})::Cint
end

"""
    aeron_add_close_handler(client, pair)

Add a handler to be called when client is closed.

NOTE: This function blocks until the handler is added by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_add_close_handler(aeron_t *client, aeron_on_close_client_pair_t *pair);
```
"""
function aeron_add_close_handler(client, pair)
    @ccall libaeron.aeron_add_close_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_close_client_pair_t})::Cint
end

"""
    aeron_remove_close_handler(client, pair)

Remove a previously added handler to be called when client is closed.

NOTE: This function blocks until the handler is removed by the client conductor thread.

# Arguments
* `client`: for the counter
* `pair`: holding the handler to call and a clientd to pass when called.
# Returns
0 for success and -1 for error
### Prototype
```c
int aeron_remove_close_handler(aeron_t *client, aeron_on_close_client_pair_t *pair);
```
"""
function aeron_remove_close_handler(client, pair)
    @ccall libaeron.aeron_remove_close_handler(client::Ptr{aeron_t}, pair::Ptr{aeron_on_close_client_pair_t})::Cint
end

struct aeron_counters_reader_buffers_stct
    values::Ptr{UInt8}
    metadata::Ptr{UInt8}
    values_length::Csize_t
    metadata_length::Csize_t
end

const aeron_counters_reader_buffers_t = aeron_counters_reader_buffers_stct

"""
    aeron_counters_reader_get_buffers(reader, buffers)

Get buffer pointers and lengths for the counters reader.

# Arguments
* `reader`: reader containing the buffers.
* `buffers`: output structure to return the buffers.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_get_buffers(aeron_counters_reader_t *reader, aeron_counters_reader_buffers_t *buffers);
```
"""
function aeron_counters_reader_get_buffers(reader, buffers)
    @ccall libaeron.aeron_counters_reader_get_buffers(reader::Ptr{aeron_counters_reader_t}, buffers::Ptr{aeron_counters_reader_buffers_t})::Cint
end

# typedef void ( * aeron_counters_reader_foreach_counter_func_t ) ( int64_t value , int32_t id , int32_t type_id , const uint8_t * key , size_t key_length , const char * label , size_t label_length , void * clientd )
"""
Function called by [`aeron_counters_reader_foreach_counter`](@ref) for each counter in the [`aeron_counters_reader_t`](@ref).

# Arguments
* `value`: of the counter.
* `id`: of the counter.
* `label`: for the counter.
* `label_length`: for the counter.
* `clientd`: to be returned in the call
"""
const aeron_counters_reader_foreach_counter_func_t = Ptr{Cvoid}

"""
    aeron_counters_reader_foreach_counter(counters_reader, func, clientd)

Iterate over the counters in the counters\\_reader and call the given function for each counter.

# Arguments
* `counters_reader`: to iterate over.
* `func`: to call for each counter.
* `clientd`: to pass for each call to func.
### Prototype
```c
void aeron_counters_reader_foreach_counter( aeron_counters_reader_t *counters_reader, aeron_counters_reader_foreach_counter_func_t func, void *clientd);
```
"""
function aeron_counters_reader_foreach_counter(counters_reader, func, clientd)
    @ccall libaeron.aeron_counters_reader_foreach_counter(counters_reader::Ptr{aeron_counters_reader_t}, func::aeron_counters_reader_foreach_counter_func_t, clientd::Ptr{Cvoid})::Cvoid
end

"""
    aeron_counters_reader_find_by_type_id_and_registration_id(counters_reader, type_id, registration_id)

Iterate over allocated counters and find the first matching a given type id and registration id.

# Arguments
* `counters_reader`:
* `type_id`: to find.
* `registration_id`: to find.
# Returns
the counter id if found otherwise [`AERON_NULL_COUNTER_ID`](@ref).
### Prototype
```c
int32_t aeron_counters_reader_find_by_type_id_and_registration_id( aeron_counters_reader_t *counters_reader, int32_t type_id, int64_t registration_id);
```
"""
function aeron_counters_reader_find_by_type_id_and_registration_id(counters_reader, type_id, registration_id)
    @ccall libaeron.aeron_counters_reader_find_by_type_id_and_registration_id(counters_reader::Ptr{aeron_counters_reader_t}, type_id::Int32, registration_id::Int64)::Int32
end

"""
    aeron_counters_reader_max_counter_id(reader)

Get the current max counter id.

# Arguments
* `reader`: to query
# Returns
-1 on failure, max counter id on success.
### Prototype
```c
int32_t aeron_counters_reader_max_counter_id(aeron_counters_reader_t *reader);
```
"""
function aeron_counters_reader_max_counter_id(reader)
    @ccall libaeron.aeron_counters_reader_max_counter_id(reader::Ptr{aeron_counters_reader_t})::Int32
end

"""
    aeron_counters_reader_addr(counters_reader, counter_id)

Get the address for a counter.

# Arguments
* `counters_reader`: that contains the counter
* `counter_id`: to find
# Returns
address of the counter value
### Prototype
```c
int64_t *aeron_counters_reader_addr(aeron_counters_reader_t *counters_reader, int32_t counter_id);
```
"""
function aeron_counters_reader_addr(counters_reader, counter_id)
    @ccall libaeron.aeron_counters_reader_addr(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32)::Ptr{Int64}
end

"""
    aeron_counters_reader_counter_registration_id(counters_reader, counter_id, registration_id)

Get the registration id assigned to a counter.

# Arguments
* `counters_reader`: representing the this pointer.
* `counter_id`: for which the registration id is requested.
* `registration_id`: pointer for value to be set on success.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_counter_registration_id( aeron_counters_reader_t *counters_reader, int32_t counter_id, int64_t *registration_id);
```
"""
function aeron_counters_reader_counter_registration_id(counters_reader, counter_id, registration_id)
    @ccall libaeron.aeron_counters_reader_counter_registration_id(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, registration_id::Ptr{Int64})::Cint
end

"""
    aeron_counters_reader_counter_owner_id(counters_reader, counter_id, owner_id)

Get the owner id assigned to a counter which will typically be the client id.

# Arguments
* `counters_reader`: representing the this pointer.
* `counter_id`: for which the owner id is requested.
* `owner_id`: pointer for value to be set on success.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_counter_owner_id( aeron_counters_reader_t *counters_reader, int32_t counter_id, int64_t *owner_id);
```
"""
function aeron_counters_reader_counter_owner_id(counters_reader, counter_id, owner_id)
    @ccall libaeron.aeron_counters_reader_counter_owner_id(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, owner_id::Ptr{Int64})::Cint
end

"""
    aeron_counters_reader_counter_reference_id(counters_reader, counter_id, reference_id)

Get the reference id assigned to a counter which will typically be the registration id of an associated Image, Subscription, Publication, etc.

# Arguments
* `counters_reader`: representing the this pointer.
* `counter_id`: for which the reference id is requested.
* `reference_id`: pointer for value to be set on success.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_counter_reference_id( aeron_counters_reader_t *counters_reader, int32_t counter_id, int64_t *reference_id);
```
"""
function aeron_counters_reader_counter_reference_id(counters_reader, counter_id, reference_id)
    @ccall libaeron.aeron_counters_reader_counter_reference_id(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, reference_id::Ptr{Int64})::Cint
end

"""
    aeron_counters_reader_counter_state(counters_reader, counter_id, state)

Get the state for a counter.

# Arguments
* `counters_reader`: that contains the counter
* `counter_id`: to find
* `state`: out pointer for the current state to be stored in.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_counter_state(aeron_counters_reader_t *counters_reader, int32_t counter_id, int32_t *state);
```
"""
function aeron_counters_reader_counter_state(counters_reader, counter_id, state)
    @ccall libaeron.aeron_counters_reader_counter_state(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, state::Ptr{Int32})::Cint
end

"""
    aeron_counters_reader_counter_type_id(counters_reader, counter_id, type_id)

Get the type id for a counter.

# Arguments
* `counters_reader`: that contains the counter
* `counter_id`: to find
* `type`: id out pointer for the current state to be stored in.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_counter_type_id( aeron_counters_reader_t *counters_reader, int32_t counter_id, int32_t *type_id);
```
"""
function aeron_counters_reader_counter_type_id(counters_reader, counter_id, type_id)
    @ccall libaeron.aeron_counters_reader_counter_type_id(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, type_id::Ptr{Int32})::Cint
end

"""
    aeron_counters_reader_counter_label(counters_reader, counter_id, buffer, buffer_length)

Get the label for a counter.

# Arguments
* `counters_reader`: that contains the counter
* `counter_id`: to find
* `buffer`: to store the counter in.
* `buffer_length`: length of the output buffer
# Returns
-1 on failure, number of characters copied to buffer on success.
### Prototype
```c
int aeron_counters_reader_counter_label( aeron_counters_reader_t *counters_reader, int32_t counter_id, char *buffer, size_t buffer_length);
```
"""
function aeron_counters_reader_counter_label(counters_reader, counter_id, buffer, buffer_length)
    @ccall libaeron.aeron_counters_reader_counter_label(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, buffer::Cstring, buffer_length::Csize_t)::Cint
end

"""
    aeron_counters_reader_free_for_reuse_deadline_ms(counters_reader, counter_id, deadline_ms)

Get the free for reuse deadline (ms) for a counter.

# Arguments
* `counters_reader`: that contains the counter.
* `counter_id`: to find.
* `deadline_ms`: output value to store the deadline.
# Returns
-1 on failure, 0 on success.
### Prototype
```c
int aeron_counters_reader_free_for_reuse_deadline_ms( aeron_counters_reader_t *counters_reader, int32_t counter_id, int64_t *deadline_ms);
```
"""
function aeron_counters_reader_free_for_reuse_deadline_ms(counters_reader, counter_id, deadline_ms)
    @ccall libaeron.aeron_counters_reader_free_for_reuse_deadline_ms(counters_reader::Ptr{aeron_counters_reader_t}, counter_id::Int32, deadline_ms::Ptr{Int64})::Cint
end

# typedef int64_t ( * aeron_reserved_value_supplier_t ) ( void * clientd , uint8_t * buffer , size_t frame_length )
"""
Function called when filling in the reserved value field of a message.

# Arguments
* `clientd`: passed to the offer function.
* `buffer`: of the entire frame, including Aeron data header.
* `frame_length`: of the entire frame.
"""
const aeron_reserved_value_supplier_t = Ptr{Cvoid}

struct aeron_iovec_stct
    iov_base::Ptr{UInt8}
    iov_len::Csize_t
end

const aeron_iovec_t = aeron_iovec_stct

"""
    aeron_buffer_claim_commit(buffer_claim)

Commit the given buffer\\_claim as a complete message available for consumption.

# Arguments
* `buffer_claim`: to commit.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_buffer_claim_commit(aeron_buffer_claim_t *buffer_claim);
```
"""
function aeron_buffer_claim_commit(buffer_claim)
    @ccall libaeron.aeron_buffer_claim_commit(buffer_claim::Ptr{aeron_buffer_claim_t})::Cint
end

"""
    aeron_buffer_claim_abort(buffer_claim)

Abort the given buffer\\_claim and assign its position as padding.

# Arguments
* `buffer_claim`: to abort.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_buffer_claim_abort(aeron_buffer_claim_t *buffer_claim);
```
"""
function aeron_buffer_claim_abort(buffer_claim)
    @ccall libaeron.aeron_buffer_claim_abort(buffer_claim::Ptr{aeron_buffer_claim_t})::Cint
end

"""
    aeron_publication_constants_stct

Configuration for a publication that does not change during it's lifetime.
"""
struct aeron_publication_constants_stct
    channel::Cstring
    original_registration_id::Int64
    registration_id::Int64
    max_possible_position::Int64
    position_bits_to_shift::Csize_t
    term_buffer_length::Csize_t
    max_message_length::Csize_t
    max_payload_length::Csize_t
    stream_id::Int32
    session_id::Int32
    initial_term_id::Int32
    publication_limit_counter_id::Int32
    channel_status_indicator_id::Int32
end

"""
Configuration for a publication that does not change during it's lifetime.
"""
const aeron_publication_constants_t = aeron_publication_constants_stct

"""
    aeron_publication_offer(publication, buffer, length, reserved_value_supplier, clientd)

Non-blocking publish of a buffer containing a message.

# Arguments
* `publication`: to publish on.
* `buffer`: to publish.
* `length`: of the buffer.
* `reserved_value_supplier`: to use for setting the reserved value field or NULL.
* `clientd`: to pass to the reserved\\_value\\_supplier.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_publication_offer( aeron_publication_t *publication, const uint8_t *buffer, size_t length, aeron_reserved_value_supplier_t reserved_value_supplier, void *clientd);
```
"""
function aeron_publication_offer(publication, buffer, length, reserved_value_supplier, clientd)
    @ccall libaeron.aeron_publication_offer(publication::Ptr{aeron_publication_t}, buffer::Ptr{UInt8}, length::Csize_t, reserved_value_supplier::aeron_reserved_value_supplier_t, clientd::Ptr{Cvoid})::Int64
end

"""
    aeron_publication_offerv(publication, iov, iovcnt, reserved_value_supplier, clientd)

Non-blocking publish by gathering buffer vectors into a message.

# Arguments
* `publication`: to publish on.
* `iov`: array for the vectors
* `iovcnt`: of the number of vectors
* `reserved_value_supplier`: to use for setting the reserved value field or NULL.
* `clientd`: to pass to the reserved\\_value\\_supplier.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_publication_offerv( aeron_publication_t *publication, aeron_iovec_t *iov, size_t iovcnt, aeron_reserved_value_supplier_t reserved_value_supplier, void *clientd);
```
"""
function aeron_publication_offerv(publication, iov, iovcnt, reserved_value_supplier, clientd)
    @ccall libaeron.aeron_publication_offerv(publication::Ptr{aeron_publication_t}, iov::Ptr{aeron_iovec_t}, iovcnt::Csize_t, reserved_value_supplier::aeron_reserved_value_supplier_t, clientd::Ptr{Cvoid})::Int64
end

"""
    aeron_publication_try_claim(publication, length, buffer_claim)

Try to claim a range in the publication log into which a message can be written with zero copy semantics. Once the message has been written then [`aeron_buffer_claim_commit`](@ref) should be called thus making it available. A claim length cannot be greater than max payload length. <p> <b>Note:</b> This method can only be used for message lengths less than MTU length minus header. If the claim is held for more than the aeron.publication.unblock.timeout system property then the driver will assume the publication thread is dead and will unblock the claim thus allowing other threads to make progress and other claims to be sent to reach end-of-stream (EOS).

```c++
 aeron_buffer_claim_t buffer_claim;

 if (aeron_publication_try_claim(publication, length, &buffer_claim) > 0L)
 {
     // work with buffer_claim->data directly.
     aeron_buffer_claim_commit(&buffer_claim);
 }
```

# Arguments
* `publication`: to publish to.
* `length`: of the message.
* `buffer_claim`: to be populated if the claim succeeds.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_publication_try_claim( aeron_publication_t *publication, size_t length, aeron_buffer_claim_t *buffer_claim);
```
"""
function aeron_publication_try_claim(publication, length, buffer_claim)
    @ccall libaeron.aeron_publication_try_claim(publication::Ptr{aeron_publication_t}, length::Csize_t, buffer_claim::Ptr{aeron_buffer_claim_t})::Int64
end

"""
    aeron_publication_channel_status(publication)

Get the status of the media channel for this publication. <p> The status will be ERRORED (-1) if a socket exception occurs on setup and ACTIVE (1) if all is well.

# Arguments
* `publication`: to check status of.
# Returns
1 for ACTIVE, -1 for ERRORED
### Prototype
```c
int64_t aeron_publication_channel_status(aeron_publication_t *publication);
```
"""
function aeron_publication_channel_status(publication)
    @ccall libaeron.aeron_publication_channel_status(publication::Ptr{aeron_publication_t})::Int64
end

"""
    aeron_publication_is_closed(publication)

Has the publication closed?

# Arguments
* `publication`: to check
# Returns
true if this publication is closed.
### Prototype
```c
bool aeron_publication_is_closed(aeron_publication_t *publication);
```
"""
function aeron_publication_is_closed(publication)
    @ccall libaeron.aeron_publication_is_closed(publication::Ptr{aeron_publication_t})::Bool
end

"""
    aeron_publication_is_connected(publication)

Has the publication seen an active Subscriber recently?

# Arguments
* `publication`: to check.
# Returns
true if this publication has recently seen an active subscriber otherwise false.
### Prototype
```c
bool aeron_publication_is_connected(aeron_publication_t *publication);
```
"""
function aeron_publication_is_connected(publication)
    @ccall libaeron.aeron_publication_is_connected(publication::Ptr{aeron_publication_t})::Bool
end

"""
    aeron_publication_constants(publication, constants)

Fill in a structure with the constants in use by a publication.

# Arguments
* `publication`: to get the constants for.
* `constants`: structure to fill in with the constants
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_publication_constants(aeron_publication_t *publication, aeron_publication_constants_t *constants);
```
"""
function aeron_publication_constants(publication, constants)
    @ccall libaeron.aeron_publication_constants(publication::Ptr{aeron_publication_t}, constants::Ptr{aeron_publication_constants_t})::Cint
end

"""
    aeron_publication_position(publication)

Get the current position to which the publication has advanced for this stream.

# Arguments
* `publication`: to query.
# Returns
the current position to which the publication has advanced for this stream or a negative error value.
### Prototype
```c
int64_t aeron_publication_position(aeron_publication_t *publication);
```
"""
function aeron_publication_position(publication)
    @ccall libaeron.aeron_publication_position(publication::Ptr{aeron_publication_t})::Int64
end

"""
    aeron_publication_position_limit(publication)

Get the position limit beyond which this publication will be back pressured.

This should only be used as a guide to determine when back pressure is likely to be applied.

# Arguments
* `publication`: to query.
# Returns
the position limit beyond which this publication will be back pressured or a negative error value.
### Prototype
```c
int64_t aeron_publication_position_limit(aeron_publication_t *publication);
```
"""
function aeron_publication_position_limit(publication)
    @ccall libaeron.aeron_publication_position_limit(publication::Ptr{aeron_publication_t})::Int64
end

"""
    aeron_publication_async_add_destination(async, client, publication, uri)

Add a destination manually to a multi-destination-cast publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to add destination to.
* `uri`: for the destination to add.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_publication_async_add_destination( aeron_async_destination_t **async, aeron_t *client, aeron_publication_t *publication, const char *uri);
```
"""
function aeron_publication_async_add_destination(async, client, publication, uri)
    @ccall libaeron.aeron_publication_async_add_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_publication_t}, uri::Cstring)::Cint
end

"""
    aeron_publication_async_remove_destination(async, client, publication, uri)

Remove a destination manually from a multi-destination-cast publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to remove destination from.
* `uri`: for the destination to remove.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_publication_async_remove_destination( aeron_async_destination_t **async, aeron_t *client, aeron_publication_t *publication, const char *uri);
```
"""
function aeron_publication_async_remove_destination(async, client, publication, uri)
    @ccall libaeron.aeron_publication_async_remove_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_publication_t}, uri::Cstring)::Cint
end

"""
    aeron_publication_async_remove_destination_by_id(async, client, publication, destination_registration_id)

Remove a destination manually from a multi-destination-cast publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to remove destination from.
* `destination_registration_id`: for the destination to remove.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_publication_async_remove_destination_by_id( aeron_async_destination_t **async, aeron_t *client, aeron_publication_t *publication, int64_t destination_registration_id);
```
"""
function aeron_publication_async_remove_destination_by_id(async, client, publication, destination_registration_id)
    @ccall libaeron.aeron_publication_async_remove_destination_by_id(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_publication_t}, destination_registration_id::Int64)::Cint
end

"""
    aeron_publication_async_destination_poll(async)

Poll the completion of the add/remove of a destination to/from a publication.

# Arguments
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_publication_async_destination_poll(aeron_async_destination_t *async);
```
"""
function aeron_publication_async_destination_poll(async)
    @ccall libaeron.aeron_publication_async_destination_poll(async::Ptr{aeron_async_destination_t})::Cint
end

"""
    aeron_exclusive_publication_async_add_destination(async, client, publication, uri)

Add a destination manually to a multi-destination-cast exclusive publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to add destination to.
* `uri`: for the destination to add.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_exclusive_publication_async_add_destination( aeron_async_destination_t **async, aeron_t *client, aeron_exclusive_publication_t *publication, const char *uri);
```
"""
function aeron_exclusive_publication_async_add_destination(async, client, publication, uri)
    @ccall libaeron.aeron_exclusive_publication_async_add_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_exclusive_publication_t}, uri::Cstring)::Cint
end

"""
    aeron_exclusive_publication_async_remove_destination(async, client, publication, uri)

Remove a destination manually from a multi-destination-cast exclusive publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to remove destination from.
* `uri`: for the destination to remove.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_exclusive_publication_async_remove_destination( aeron_async_destination_t **async, aeron_t *client, aeron_exclusive_publication_t *publication, const char *uri);
```
"""
function aeron_exclusive_publication_async_remove_destination(async, client, publication, uri)
    @ccall libaeron.aeron_exclusive_publication_async_remove_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_exclusive_publication_t}, uri::Cstring)::Cint
end

"""
    aeron_exclusive_publication_async_remove_destination_by_id(async, client, publication, destination_registration_id)

Remove a destination manually from a multi-destination-cast publication.

# Arguments
* `async`: object to use for polling completion.
* `publication`: to remove destination from.
* `destination_registration_id`: for the destination to remove.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_exclusive_publication_async_remove_destination_by_id( aeron_async_destination_t **async, aeron_t *client, aeron_exclusive_publication_t *publication, int64_t destination_registration_id);
```
"""
function aeron_exclusive_publication_async_remove_destination_by_id(async, client, publication, destination_registration_id)
    @ccall libaeron.aeron_exclusive_publication_async_remove_destination_by_id(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, publication::Ptr{aeron_exclusive_publication_t}, destination_registration_id::Int64)::Cint
end

"""
    aeron_exclusive_publication_async_destination_poll(async)

Poll the completion of the add/remove of a destination to/from an exclusive publication.

# Arguments
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_exclusive_publication_async_destination_poll(aeron_async_destination_t *async);
```
"""
function aeron_exclusive_publication_async_destination_poll(async)
    @ccall libaeron.aeron_exclusive_publication_async_destination_poll(async::Ptr{aeron_async_destination_t})::Cint
end

"""
    aeron_publication_close(publication, on_close_complete, on_close_complete_clientd)

Asynchronously close the publication. Will callback on the on\\_complete notification when the subscription is closed. The callback is optional, use NULL for the on\\_complete callback if not required.

# Arguments
* `publication`: to close
* `on_close_complete`: optional callback to execute once the subscription has been closed and freed. This may happen on a separate thread, so the caller should ensure that clientd has the appropriate lifetime.
* `on_close_complete_clientd`: parameter to pass to the on\\_complete callback.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_publication_close( aeron_publication_t *publication, aeron_notification_t on_close_complete, void *on_close_complete_clientd);
```
"""
function aeron_publication_close(publication, on_close_complete, on_close_complete_clientd)
    @ccall libaeron.aeron_publication_close(publication::Ptr{aeron_publication_t}, on_close_complete::aeron_notification_t, on_close_complete_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_publication_channel(publication)

Get the publication's channel

# Arguments
* `publication`: this
# Returns
channel uri string
### Prototype
```c
const char *aeron_publication_channel(aeron_publication_t *publication);
```
"""
function aeron_publication_channel(publication)
    @ccall libaeron.aeron_publication_channel(publication::Ptr{aeron_publication_t})::Cstring
end

"""
    aeron_publication_stream_id(publication)

Get the publication's stream id

# Arguments
* `publication`: this
# Returns
stream id
### Prototype
```c
int32_t aeron_publication_stream_id(aeron_publication_t *publication);
```
"""
function aeron_publication_stream_id(publication)
    @ccall libaeron.aeron_publication_stream_id(publication::Ptr{aeron_publication_t})::Int32
end

"""
    aeron_publication_session_id(publication)

Get the publication's session id

# Arguments
* `publication`: this
# Returns
session id
### Prototype
```c
int32_t aeron_publication_session_id(aeron_publication_t *publication);
```
"""
function aeron_publication_session_id(publication)
    @ccall libaeron.aeron_publication_session_id(publication::Ptr{aeron_publication_t})::Int32
end

"""
    aeron_publication_local_sockaddrs(publication, address_vec, address_vec_len)

Get all of the local socket addresses for this publication. Typically only one representing the control address.

# Arguments
* `subscription`: to query
* `address_vec`: to hold the received addresses
* `address_vec_len`: available length of the vector to hold the addresses
# Returns
number of addresses found or -1 if there is an error.
# See also
[`aeron_subscription_local_sockaddrs`](@ref)

### Prototype
```c
int aeron_publication_local_sockaddrs( aeron_publication_t *publication, aeron_iovec_t *address_vec, size_t address_vec_len);
```
"""
function aeron_publication_local_sockaddrs(publication, address_vec, address_vec_len)
    @ccall libaeron.aeron_publication_local_sockaddrs(publication::Ptr{aeron_publication_t}, address_vec::Ptr{aeron_iovec_t}, address_vec_len::Csize_t)::Cint
end

"""
    aeron_exclusive_publication_offer(publication, buffer, length, reserved_value_supplier, clientd)

Non-blocking publish of a buffer containing a message.

# Arguments
* `publication`: to publish on.
* `buffer`: to publish.
* `length`: of the buffer.
* `reserved_value_supplier`: to use for setting the reserved value field or NULL.
* `clientd`: to pass to the reserved\\_value\\_supplier.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_offer( aeron_exclusive_publication_t *publication, const uint8_t *buffer, size_t length, aeron_reserved_value_supplier_t reserved_value_supplier, void *clientd);
```
"""
function aeron_exclusive_publication_offer(publication, buffer, length, reserved_value_supplier, clientd)
    @ccall libaeron.aeron_exclusive_publication_offer(publication::Ptr{aeron_exclusive_publication_t}, buffer::Ptr{UInt8}, length::Csize_t, reserved_value_supplier::aeron_reserved_value_supplier_t, clientd::Ptr{Cvoid})::Int64
end

"""
    aeron_exclusive_publication_offerv(publication, iov, iovcnt, reserved_value_supplier, clientd)

Non-blocking publish by gathering buffer vectors into a message.

# Arguments
* `publication`: to publish on.
* `iov`: array for the vectors
* `iovcnt`: of the number of vectors
* `reserved_value_supplier`: to use for setting the reserved value field or NULL.
* `clientd`: to pass to the reserved\\_value\\_supplier.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_offerv( aeron_exclusive_publication_t *publication, aeron_iovec_t *iov, size_t iovcnt, aeron_reserved_value_supplier_t reserved_value_supplier, void *clientd);
```
"""
function aeron_exclusive_publication_offerv(publication, iov, iovcnt, reserved_value_supplier, clientd)
    @ccall libaeron.aeron_exclusive_publication_offerv(publication::Ptr{aeron_exclusive_publication_t}, iov::Ptr{aeron_iovec_t}, iovcnt::Csize_t, reserved_value_supplier::aeron_reserved_value_supplier_t, clientd::Ptr{Cvoid})::Int64
end

"""
    aeron_exclusive_publication_try_claim(publication, length, buffer_claim)

Try to claim a range in the publication log into which a message can be written with zero copy semantics. Once the message has been written then [`aeron_buffer_claim_commit`](@ref) should be called thus making it available. A claim length cannot be greater than max payload length. <p> <b>Note:</b> This method can only be used for message lengths less than MTU length minus header.

```c++
 aeron_buffer_claim_t buffer_claim;

 if (aeron_exclusive_publication_try_claim(publication, length, &buffer_claim) > 0L)
 {
     // work with buffer_claim->data directly.
     aeron_buffer_claim_commit(&buffer_claim);
 }
```

# Arguments
* `publication`: to publish to.
* `length`: of the message.
* `buffer_claim`: to be populated if the claim succeeds.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_try_claim( aeron_exclusive_publication_t *publication, size_t length, aeron_buffer_claim_t *buffer_claim);
```
"""
function aeron_exclusive_publication_try_claim(publication, length, buffer_claim)
    @ccall libaeron.aeron_exclusive_publication_try_claim(publication::Ptr{aeron_exclusive_publication_t}, length::Csize_t, buffer_claim::Ptr{aeron_buffer_claim_t})::Int64
end

"""
    aeron_exclusive_publication_append_padding(publication, length)

Append a padding record log of a given length to make up the log to a position.

# Arguments
* `length`: of the range to claim, in bytes.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_append_padding(aeron_exclusive_publication_t *publication, size_t length);
```
"""
function aeron_exclusive_publication_append_padding(publication, length)
    @ccall libaeron.aeron_exclusive_publication_append_padding(publication::Ptr{aeron_exclusive_publication_t}, length::Csize_t)::Int64
end

"""
    aeron_exclusive_publication_offer_block(publication, buffer, length)

Offer a block of pre-formatted message fragments directly into the current term.

# Arguments
* `buffer`: containing the pre-formatted block of message fragments.
* `offset`: offset in the buffer at which the first fragment begins.
* `length`: in bytes of the encoded block.
# Returns
the new stream position otherwise a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_offer_block( aeron_exclusive_publication_t *publication, const uint8_t *buffer, size_t length);
```
"""
function aeron_exclusive_publication_offer_block(publication, buffer, length)
    @ccall libaeron.aeron_exclusive_publication_offer_block(publication::Ptr{aeron_exclusive_publication_t}, buffer::Ptr{UInt8}, length::Csize_t)::Int64
end

"""
    aeron_exclusive_publication_channel_status(publication)

Get the status of the media channel for this publication. <p> The status will be ERRORED (-1) if a socket exception occurs on setup and ACTIVE (1) if all is well.

# Arguments
* `publication`: to check status of.
# Returns
1 for ACTIVE, -1 for ERRORED
### Prototype
```c
int64_t aeron_exclusive_publication_channel_status(aeron_exclusive_publication_t *publication);
```
"""
function aeron_exclusive_publication_channel_status(publication)
    @ccall libaeron.aeron_exclusive_publication_channel_status(publication::Ptr{aeron_exclusive_publication_t})::Int64
end

"""
    aeron_exclusive_publication_constants(publication, constants)

Fill in a structure with the constants in use by a publication.

# Arguments
* `publication`: to get the constants for.
* `constants`: structure to fill in with the constants
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_exclusive_publication_constants( aeron_exclusive_publication_t *publication, aeron_publication_constants_t *constants);
```
"""
function aeron_exclusive_publication_constants(publication, constants)
    @ccall libaeron.aeron_exclusive_publication_constants(publication::Ptr{aeron_exclusive_publication_t}, constants::Ptr{aeron_publication_constants_t})::Cint
end

"""
    aeron_exclusive_publication_position(publication)

Get the current position to which the publication has advanced for this stream.

# Arguments
* `publication`: to query.
# Returns
the current position to which the publication has advanced for this stream or a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_position(aeron_exclusive_publication_t *publication);
```
"""
function aeron_exclusive_publication_position(publication)
    @ccall libaeron.aeron_exclusive_publication_position(publication::Ptr{aeron_exclusive_publication_t})::Int64
end

"""
    aeron_exclusive_publication_position_limit(publication)

Get the position limit beyond which this publication will be back pressured.

This should only be used as a guide to determine when back pressure is likely to be applied.

# Arguments
* `publication`: to query.
# Returns
the position limit beyond which this publication will be back pressured or a negative error value.
### Prototype
```c
int64_t aeron_exclusive_publication_position_limit(aeron_exclusive_publication_t *publication);
```
"""
function aeron_exclusive_publication_position_limit(publication)
    @ccall libaeron.aeron_exclusive_publication_position_limit(publication::Ptr{aeron_exclusive_publication_t})::Int64
end

"""
    aeron_exclusive_publication_close(publication, on_close_complete, on_close_complete_clientd)

Asynchronously close the publication.

# Arguments
* `publication`: to close
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_exclusive_publication_close( aeron_exclusive_publication_t *publication, aeron_notification_t on_close_complete, void *on_close_complete_clientd);
```
"""
function aeron_exclusive_publication_close(publication, on_close_complete, on_close_complete_clientd)
    @ccall libaeron.aeron_exclusive_publication_close(publication::Ptr{aeron_exclusive_publication_t}, on_close_complete::aeron_notification_t, on_close_complete_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_exclusive_publication_is_closed(publication)

Has the exclusive publication closed?

# Arguments
* `publication`: to check
# Returns
true if this publication is closed.
### Prototype
```c
bool aeron_exclusive_publication_is_closed(aeron_exclusive_publication_t *publication);
```
"""
function aeron_exclusive_publication_is_closed(publication)
    @ccall libaeron.aeron_exclusive_publication_is_closed(publication::Ptr{aeron_exclusive_publication_t})::Bool
end

"""
    aeron_exclusive_publication_is_connected(publication)

Has the exclusive publication seen an active Subscriber recently?

# Arguments
* `publication`: to check.
# Returns
true if this publication has recently seen an active subscriber otherwise false.
### Prototype
```c
bool aeron_exclusive_publication_is_connected(aeron_exclusive_publication_t *publication);
```
"""
function aeron_exclusive_publication_is_connected(publication)
    @ccall libaeron.aeron_exclusive_publication_is_connected(publication::Ptr{aeron_exclusive_publication_t})::Bool
end

"""
    aeron_exclusive_publication_local_sockaddrs(publication, address_vec, address_vec_len)

Get all of the local socket addresses for this exclusive publication. Typically only one representing the control address.

# Arguments
* `subscription`: to query
* `address_vec`: to hold the received addresses
* `address_vec_len`: available length of the vector to hold the addresses
# Returns
number of addresses found or -1 if there is an error.
# See also
[`aeron_subscription_local_sockaddrs`](@ref)

### Prototype
```c
int aeron_exclusive_publication_local_sockaddrs( aeron_exclusive_publication_t *publication, aeron_iovec_t *address_vec, size_t address_vec_len);
```
"""
function aeron_exclusive_publication_local_sockaddrs(publication, address_vec, address_vec_len)
    @ccall libaeron.aeron_exclusive_publication_local_sockaddrs(publication::Ptr{aeron_exclusive_publication_t}, address_vec::Ptr{aeron_iovec_t}, address_vec_len::Csize_t)::Cint
end

# typedef void ( * aeron_fragment_handler_t ) ( void * clientd , const uint8_t * buffer , size_t length , aeron_header_t * header )
"""
Callback for handling fragments of data being read from a log.

The frame will either contain a whole message or a fragment of a message to be reassembled. Messages are fragmented if greater than the frame for MTU in length.

# Arguments
* `clientd`: passed to the poll function.
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
"""
const aeron_fragment_handler_t = Ptr{Cvoid}

@cenum aeron_controlled_fragment_handler_action_en::UInt32 begin
    AERON_ACTION_ABORT = 1
    AERON_ACTION_BREAK = 2
    AERON_ACTION_COMMIT = 3
    AERON_ACTION_CONTINUE = 4
end

const aeron_controlled_fragment_handler_action_t = aeron_controlled_fragment_handler_action_en

# typedef aeron_controlled_fragment_handler_action_t ( * aeron_controlled_fragment_handler_t ) ( void * clientd , const uint8_t * buffer , size_t length , aeron_header_t * header )
"""
Callback for handling fragments of data being read from a log.

Handler for reading data that is coming from a log buffer. The frame will either contain a whole message or a fragment of a message to be reassembled. Messages are fragmented if greater than the frame for MTU in length.

# Arguments
* `clientd`: passed to the controlled poll function.
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
# Returns
The action to be taken with regard to the stream position after the callback.
"""
const aeron_controlled_fragment_handler_t = Ptr{Cvoid}

# typedef void ( * aeron_block_handler_t ) ( void * clientd , const uint8_t * buffer , size_t length , int32_t session_id , int32_t term_id )
"""
Callback for handling a block of messages being read from a log.

# Arguments
* `clientd`: passed to the block poll function.
* `buffer`: containing the block of message fragments.
* `offset`: at which the block begins, including any frame headers.
* `length`: of the block in bytes, including any frame headers that is aligned.
* `session_id`: of the stream containing this block of message fragments.
* `term_id`: of the stream containing this block of message fragments.
"""
const aeron_block_handler_t = Ptr{Cvoid}

"""
    aeron_header_values(header, values)

Get all of the field values from the header. This will do a memcpy into the supplied header\\_values\\_t pointer.

# Arguments
* `header`: to read values from.
* `values`: to copy values to, must not be null.
# Returns
0 on success, -1 on failure.
### Prototype
```c
int aeron_header_values(aeron_header_t *header, aeron_header_values_t *values);
```
"""
function aeron_header_values(header, values)
    @ccall libaeron.aeron_header_values(header::Ptr{aeron_header_t}, values::Ptr{aeron_header_values_t})::Cint
end

"""
    aeron_header_position(header)

Get the current position to which the Image has advanced on reading this message.

# Arguments
* `header`: the current header message
# Returns
the current position to which the Image has advanced on reading this message.
### Prototype
```c
int64_t aeron_header_position(aeron_header_t *header);
```
"""
function aeron_header_position(header)
    @ccall libaeron.aeron_header_position(header::Ptr{aeron_header_t})::Int64
end

"""
    aeron_header_position_bits_to_shift(header)

Get the number of times to left shift the term count to multiply by term length.

# Returns
number of times to left shift the term count to multiply by term length.
### Prototype
```c
size_t aeron_header_position_bits_to_shift(aeron_header_t *header);
```
"""
function aeron_header_position_bits_to_shift(header)
    @ccall libaeron.aeron_header_position_bits_to_shift(header::Ptr{aeron_header_t})::Csize_t
end

"""
    aeron_header_next_term_offset(header)

Calculates the offset of the frame immediately after this one.

# Returns
the offset of the next frame.
### Prototype
```c
int32_t aeron_header_next_term_offset(aeron_header_t *header);
```
"""
function aeron_header_next_term_offset(header)
    @ccall libaeron.aeron_header_next_term_offset(header::Ptr{aeron_header_t})::Int32
end

"""
    aeron_header_context(header)

Get a pointer to the context associated with this message. Only valid during poll handling. Is normally a pointer to an Image instance.

# Returns
a pointer to the context associated with this message.
### Prototype
```c
void *aeron_header_context(aeron_header_t *header);
```
"""
function aeron_header_context(header)
    @ccall libaeron.aeron_header_context(header::Ptr{aeron_header_t})::Ptr{Cvoid}
end

struct aeron_subscription_constants_stct
    channel::Cstring
    on_available_image::aeron_on_available_image_t
    on_unavailable_image::aeron_on_unavailable_image_t
    registration_id::Int64
    stream_id::Int32
    channel_status_indicator_id::Int32
end

const aeron_subscription_constants_t = aeron_subscription_constants_stct

"""
    aeron_subscription_poll(subscription, handler, clientd, fragment_limit)

Poll the images under the subscription for available message fragments. <p> Each fragment read will be a whole message if it is under MTU length. If larger than MTU then it will come as a series of fragments ordered within a session. <p> To assemble messages that span multiple fragments then use [`aeron_fragment_assembler_t`](@ref).

# Arguments
* `subscription`: to poll.
* `handler`: for handling each message fragment as it is read.
* `fragment_limit`: number of message fragments to limit when polling across multiple images.
# Returns
the number of fragments received or -1 for error.
### Prototype
```c
int aeron_subscription_poll( aeron_subscription_t *subscription, aeron_fragment_handler_t handler, void *clientd, size_t fragment_limit);
```
"""
function aeron_subscription_poll(subscription, handler, clientd, fragment_limit)
    @ccall libaeron.aeron_subscription_poll(subscription::Ptr{aeron_subscription_t}, handler::aeron_fragment_handler_t, clientd::Ptr{Cvoid}, fragment_limit::Csize_t)::Cint
end

"""
    aeron_subscription_controlled_poll(subscription, handler, clientd, fragment_limit)

Poll in a controlled manner the images under the subscription for available message fragments. Control is applied to fragments in the stream. If more fragments can be read on another stream they will even if BREAK or ABORT is returned from the fragment handler. <p> Each fragment read will be a whole message if it is under MTU length. If larger than MTU then it will come as a series of fragments ordered within a session. <p> To assemble messages that span multiple fragments then use [`aeron_controlled_fragment_assembler_t`](@ref).

# Arguments
* `subscription`: to poll.
* `handler`: for handling each message fragment as it is read.
* `fragment_limit`: number of message fragments to limit when polling across multiple images.
# Returns
the number of fragments received or -1 for error.
### Prototype
```c
int aeron_subscription_controlled_poll( aeron_subscription_t *subscription, aeron_controlled_fragment_handler_t handler, void *clientd, size_t fragment_limit);
```
"""
function aeron_subscription_controlled_poll(subscription, handler, clientd, fragment_limit)
    @ccall libaeron.aeron_subscription_controlled_poll(subscription::Ptr{aeron_subscription_t}, handler::aeron_controlled_fragment_handler_t, clientd::Ptr{Cvoid}, fragment_limit::Csize_t)::Cint
end

"""
    aeron_subscription_block_poll(subscription, handler, clientd, block_length_limit)

Poll the images under the subscription for available message fragments in blocks. <p> This method is useful for operations like bulk archiving and messaging indexing.

# Arguments
* `subscription`: to poll.
* `handler`: to receive a block of fragments from each image.
* `block_length_limit`: for each image polled.
# Returns
the number of bytes consumed or -1 for error.
### Prototype
```c
long aeron_subscription_block_poll( aeron_subscription_t *subscription, aeron_block_handler_t handler, void *clientd, size_t block_length_limit);
```
"""
function aeron_subscription_block_poll(subscription, handler, clientd, block_length_limit)
    @ccall libaeron.aeron_subscription_block_poll(subscription::Ptr{aeron_subscription_t}, handler::aeron_block_handler_t, clientd::Ptr{Cvoid}, block_length_limit::Csize_t)::Clong
end

"""
    aeron_subscription_is_connected(subscription)

Is this subscription connected by having at least one open publication image.

# Arguments
* `subscription`: to check.
# Returns
true if this subscription connected by having at least one open publication image.
### Prototype
```c
bool aeron_subscription_is_connected(aeron_subscription_t *subscription);
```
"""
function aeron_subscription_is_connected(subscription)
    @ccall libaeron.aeron_subscription_is_connected(subscription::Ptr{aeron_subscription_t})::Bool
end

"""
    aeron_subscription_constants(subscription, constants)

Fill in a structure with the constants in use by a subscription.

# Arguments
* `subscription`: to get the constants for.
* `constants`: structure to fill in with the constants
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_subscription_constants(aeron_subscription_t *subscription, aeron_subscription_constants_t *constants);
```
"""
function aeron_subscription_constants(subscription, constants)
    @ccall libaeron.aeron_subscription_constants(subscription::Ptr{aeron_subscription_t}, constants::Ptr{aeron_subscription_constants_t})::Cint
end

"""
    aeron_subscription_image_count(subscription)

Count of images associated to this subscription.

# Arguments
* `subscription`: to count images for.
# Returns
count of count associated to this subscription or -1 for error.
### Prototype
```c
int aeron_subscription_image_count(aeron_subscription_t *subscription);
```
"""
function aeron_subscription_image_count(subscription)
    @ccall libaeron.aeron_subscription_image_count(subscription::Ptr{aeron_subscription_t})::Cint
end

"""
    aeron_subscription_image_by_session_id(subscription, session_id)

Return the image associated with the given session\\_id under the given subscription.

Note: the returned image is considered retained by the application and thus must be released via aeron\\_image\\_release when finished or if the image becomes unavailable.

# Arguments
* `subscription`: to search.
* `session_id`: associated with the image.
# Returns
image associated with the given session\\_id or NULL if no image exists.
### Prototype
```c
aeron_image_t *aeron_subscription_image_by_session_id(aeron_subscription_t *subscription, int32_t session_id);
```
"""
function aeron_subscription_image_by_session_id(subscription, session_id)
    @ccall libaeron.aeron_subscription_image_by_session_id(subscription::Ptr{aeron_subscription_t}, session_id::Int32)::Ptr{aeron_image_t}
end

"""
    aeron_subscription_image_at_index(subscription, index)

Return the image at the given index.

Note: the returned image is considered retained by the application and thus must be released via aeron\\_image\\_release when finished or if the image becomes unavailable.

# Arguments
* `subscription`: to search.
* `index`: for the image.
# Returns
image at the given index or NULL if no image exists.
### Prototype
```c
aeron_image_t *aeron_subscription_image_at_index(aeron_subscription_t *subscription, size_t index);
```
"""
function aeron_subscription_image_at_index(subscription, index)
    @ccall libaeron.aeron_subscription_image_at_index(subscription::Ptr{aeron_subscription_t}, index::Csize_t)::Ptr{aeron_image_t}
end

"""
    aeron_subscription_for_each_image(subscription, handler, clientd)

Iterate over the images for this subscription calling the given function.

# Arguments
* `subscription`: to iterate over.
* `handler`: to be called for each image.
* `clientd`: to be passed to the handler.
### Prototype
```c
void aeron_subscription_for_each_image( aeron_subscription_t *subscription, void (*handler)(aeron_image_t *image, void *clientd), void *clientd);
```
"""
function aeron_subscription_for_each_image(subscription, handler, clientd)
    @ccall libaeron.aeron_subscription_for_each_image(subscription::Ptr{aeron_subscription_t}, handler::Ptr{Cvoid}, clientd::Ptr{Cvoid})::Cvoid
end

"""
    aeron_subscription_image_retain(subscription, image)

Retain the given image for access in the application.

Note: A retain call must have a corresponding release call. Note: Subscriptions are not threadsafe and should not be shared between subscribers.

# Arguments
* `subscription`: that image is part of.
* `image`: to retain
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_subscription_image_retain(aeron_subscription_t *subscription, aeron_image_t *image);
```
"""
function aeron_subscription_image_retain(subscription, image)
    @ccall libaeron.aeron_subscription_image_retain(subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})::Cint
end

"""
    aeron_subscription_image_release(subscription, image)

Release the given image and relinquish desire to use the image directly.

Note: Subscriptions are not threadsafe and should not be shared between subscribers.

# Arguments
* `subscription`: that image is part of.
* `image`: to release
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_subscription_image_release(aeron_subscription_t *subscription, aeron_image_t *image);
```
"""
function aeron_subscription_image_release(subscription, image)
    @ccall libaeron.aeron_subscription_image_release(subscription::Ptr{aeron_subscription_t}, image::Ptr{aeron_image_t})::Cint
end

"""
    aeron_subscription_is_closed(subscription)

Is the subscription closed.

# Arguments
* `subscription`: to be checked.
# Returns
true if it has been closed otherwise false.
### Prototype
```c
bool aeron_subscription_is_closed(aeron_subscription_t *subscription);
```
"""
function aeron_subscription_is_closed(subscription)
    @ccall libaeron.aeron_subscription_is_closed(subscription::Ptr{aeron_subscription_t})::Bool
end

"""
    aeron_subscription_channel_status(subscription)

Get the status of the media channel for this subscription. <p> The status will be ERRORED (-1) if a socket exception occurs on setup and ACTIVE (1) if all is well.

# Arguments
* `subscription`: to check status of.
# Returns
1 for ACTIVE, -1 for ERRORED
### Prototype
```c
int64_t aeron_subscription_channel_status(aeron_subscription_t *subscription);
```
"""
function aeron_subscription_channel_status(subscription)
    @ccall libaeron.aeron_subscription_channel_status(subscription::Ptr{aeron_subscription_t})::Int64
end

"""
    aeron_subscription_async_add_destination(async, client, subscription, uri)

Add a destination manually to a multi-destination-subscription.

# Arguments
* `async`: object to use for polling completion.
* `subscription`: to add destination to.
* `uri`: for the destination to add.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_subscription_async_add_destination( aeron_async_destination_t **async, aeron_t *client, aeron_subscription_t *subscription, const char *uri);
```
"""
function aeron_subscription_async_add_destination(async, client, subscription, uri)
    @ccall libaeron.aeron_subscription_async_add_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, subscription::Ptr{aeron_subscription_t}, uri::Cstring)::Cint
end

"""
    aeron_subscription_async_remove_destination(async, client, subscription, uri)

Remove a destination manually from a multi-destination-subscription.

# Arguments
* `async`: object to use for polling completion.
* `subscription`: to remove destination from.
* `uri`: for the destination to remove.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_subscription_async_remove_destination( aeron_async_destination_t **async, aeron_t *client, aeron_subscription_t *subscription, const char *uri);
```
"""
function aeron_subscription_async_remove_destination(async, client, subscription, uri)
    @ccall libaeron.aeron_subscription_async_remove_destination(async::Ptr{Ptr{aeron_async_destination_t}}, client::Ptr{aeron_t}, subscription::Ptr{aeron_subscription_t}, uri::Cstring)::Cint
end

"""
    aeron_subscription_async_destination_poll(async)

Poll the completion of add/remove of a destination to/from a subscription.

# Arguments
* `async`: to check for completion.
# Returns
0 for not complete (try again), 1 for completed successfully, or -1 for an error.
### Prototype
```c
int aeron_subscription_async_destination_poll(aeron_async_destination_t *async);
```
"""
function aeron_subscription_async_destination_poll(async)
    @ccall libaeron.aeron_subscription_async_destination_poll(async::Ptr{aeron_async_destination_t})::Cint
end

"""
    aeron_subscription_close(subscription, on_close_complete, on_close_complete_clientd)

Asynchronously close the subscription. Will callback on the on\\_complete notification when the subscription is closed. The callback is optional, use NULL for the on\\_complete callback if not required.

# Arguments
* `subscription`: to close
* `on_close_complete`: optional callback to execute once the subscription has been closed and freed. This may happen on a separate thread, so the caller should ensure that clientd has the appropriate lifetime.
* `on_close_complete_clientd`: parameter to pass to the on\\_complete callback.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_subscription_close( aeron_subscription_t *subscription, aeron_notification_t on_close_complete, void *on_close_complete_clientd);
```
"""
function aeron_subscription_close(subscription, on_close_complete, on_close_complete_clientd)
    @ccall libaeron.aeron_subscription_close(subscription::Ptr{aeron_subscription_t}, on_close_complete::aeron_notification_t, on_close_complete_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_subscription_local_sockaddrs(subscription, address_vec, address_vec_len)

Get all of the local socket addresses for this subscription. Multiple addresses can occur if this is a multi-destination subscription. Addresses will a string representation in numeric form. IPv6 addresses will be surrounded by '[' and ']' so that the ':' that separate the parts are distinguishable from the port delimiter. E.g. [fe80::7552:c06e:6bf4:4160]:12345. As of writing the maximum length for a formatted address is 54 bytes including the NULL terminator. [`AERON_CLIENT_MAX_LOCAL_ADDRESS_STR_LEN`](@ref) is defined to provide enough space to fit the returned string. Returned strings will be NULL terminated. If the buffer to hold the address can not hold enough of the message it will be truncated and the last character will be null.

If the address\\_vec\\_len is less the total number of addresses available then the first addresses found up to that length will be placed into the address\\_vec. However the function will return the total number of addresses available so if if that is larger than the input array then the client code may wish to re-query with a larger array to get them all.

# Arguments
* `subscription`: to query
* `address_vec`: to hold the received addresses
* `address_vec_len`: available length of the vector to hold the addresses
# Returns
number of addresses found or -1 if there is an error.
### Prototype
```c
int aeron_subscription_local_sockaddrs( aeron_subscription_t *subscription, aeron_iovec_t *address_vec, size_t address_vec_len);
```
"""
function aeron_subscription_local_sockaddrs(subscription, address_vec, address_vec_len)
    @ccall libaeron.aeron_subscription_local_sockaddrs(subscription::Ptr{aeron_subscription_t}, address_vec::Ptr{aeron_iovec_t}, address_vec_len::Csize_t)::Cint
end

"""
    aeron_subscription_resolved_endpoint(subscription, address, address_len)

Retrieves the first local socket address for this subscription. If this is not MDS then it will be the one representing endpoint for this subscription.

# Arguments
* `subscription`: to query
* `address`: for the received address
* `address_len`: available length for the copied address.
# Returns
-1 on error, 0 if address not found, 1 if address is found.
# See also
[`aeron_subscription_local_sockaddrs`](@ref)

### Prototype
```c
int aeron_subscription_resolved_endpoint(aeron_subscription_t *subscription, const char *address, size_t address_len);
```
"""
function aeron_subscription_resolved_endpoint(subscription, address, address_len)
    @ccall libaeron.aeron_subscription_resolved_endpoint(subscription::Ptr{aeron_subscription_t}, address::Cstring, address_len::Csize_t)::Cint
end

"""
    aeron_subscription_try_resolve_channel_endpoint_port(subscription, uri, uri_len)

Retrieves the channel URI for this subscription with any wildcard ports filled in. If the channel is not UDP or does not have a wildcard port (<code>0</code>), then it will return the original URI.

# Arguments
* `subscription`: to query
* `uri`: buffer to hold the resolved uri
* `uri_len`: length of the buffer
# Returns
-1 on failure or the number of bytes written to the buffer (excluding the NULL terminator). Writing is done on a per key basis, so if the buffer was truncated before writing completed, it will only include the byte count up to the key that overflowed. However, the invariant that if the number returned >= uri\\_len, then output will have been truncated.
### Prototype
```c
int aeron_subscription_try_resolve_channel_endpoint_port( aeron_subscription_t *subscription, char *uri, size_t uri_len);
```
"""
function aeron_subscription_try_resolve_channel_endpoint_port(subscription, uri, uri_len)
    @ccall libaeron.aeron_subscription_try_resolve_channel_endpoint_port(subscription::Ptr{aeron_subscription_t}, uri::Cstring, uri_len::Csize_t)::Cint
end

"""
    aeron_image_constants_stct

Configuration for an image that does not change during it's lifetime.
"""
struct aeron_image_constants_stct
    subscription::Ptr{aeron_subscription_t}
    source_identity::Cstring
    correlation_id::Int64
    join_position::Int64
    position_bits_to_shift::Csize_t
    term_buffer_length::Csize_t
    mtu_length::Csize_t
    session_id::Int32
    initial_term_id::Int32
    subscriber_position_id::Int32
end

"""
Configuration for an image that does not change during it's lifetime.
"""
const aeron_image_constants_t = aeron_image_constants_stct

"""
    aeron_image_constants(image, constants)

Fill in a structure with the constants in use by a image.

# Arguments
* `image`: to get the constants for.
* `constants`: structure to fill in with the constants
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_image_constants(aeron_image_t *image, aeron_image_constants_t *constants);
```
"""
function aeron_image_constants(image, constants)
    @ccall libaeron.aeron_image_constants(image::Ptr{aeron_image_t}, constants::Ptr{aeron_image_constants_t})::Cint
end

"""
    aeron_image_position(image)

The position this image has been consumed to by the subscriber.

# Arguments
* `image`: to query position of.
# Returns
the position this image has been consumed to by the subscriber.
### Prototype
```c
int64_t aeron_image_position(aeron_image_t *image);
```
"""
function aeron_image_position(image)
    @ccall libaeron.aeron_image_position(image::Ptr{aeron_image_t})::Int64
end

"""
    aeron_image_set_position(image, position)

Set the subscriber position for this image to indicate where it has been consumed to.

# Arguments
* `image`: to set the position of.
* `new_position`: for the consumption point.
### Prototype
```c
int aeron_image_set_position(aeron_image_t *image, int64_t position);
```
"""
function aeron_image_set_position(image, position)
    @ccall libaeron.aeron_image_set_position(image::Ptr{aeron_image_t}, position::Int64)::Cint
end

"""
    aeron_image_is_end_of_stream(image)

Is the current consumed position at the end of the stream?

# Arguments
* `image`: to check.
# Returns
true if at the end of the stream or false if not.
### Prototype
```c
bool aeron_image_is_end_of_stream(aeron_image_t *image);
```
"""
function aeron_image_is_end_of_stream(image)
    @ccall libaeron.aeron_image_is_end_of_stream(image::Ptr{aeron_image_t})::Bool
end

"""
    aeron_image_end_of_stream_position(image)

The position the stream reached when EOS was received from the publisher. The position will be INT64\\_MAX until the stream ends and EOS is set.

# Arguments
* `image`: to check.
# Returns
position the stream reached when EOS was received from the publisher.
### Prototype
```c
int64_t aeron_image_end_of_stream_position(aeron_image_t *image);
```
"""
function aeron_image_end_of_stream_position(image)
    @ccall libaeron.aeron_image_end_of_stream_position(image::Ptr{aeron_image_t})::Int64
end

"""
    aeron_image_active_transport_count(image)

Count of observed active transports within the image liveness timeout.

If the image is closed, then this is 0. This may also be 0 if no actual datagrams have arrived. IPC Images also will be 0.

# Arguments
* `image`: to check.
# Returns
count of active transports - 0 if Image is closed, no datagrams yet, or IPC. Or -1 for error.
### Prototype
```c
int aeron_image_active_transport_count(aeron_image_t *image);
```
"""
function aeron_image_active_transport_count(image)
    @ccall libaeron.aeron_image_active_transport_count(image::Ptr{aeron_image_t})::Cint
end

"""
    aeron_image_poll(image, handler, clientd, fragment_limit)

Poll for new messages in a stream. If new messages are found beyond the last consumed position then they will be delivered to the handler up to a limited number of fragments as specified. <p> Use a fragment assembler to assemble messages which span multiple fragments.

# Arguments
* `image`: to poll.
* `handler`: to which message fragments are delivered.
* `clientd`: to pass to the handler.
* `fragment_limit`: for the number of fragments to be consumed during one polling operation.
# Returns
the number of fragments that have been consumed or -1 for error.
### Prototype
```c
int aeron_image_poll(aeron_image_t *image, aeron_fragment_handler_t handler, void *clientd, size_t fragment_limit);
```
"""
function aeron_image_poll(image, handler, clientd, fragment_limit)
    @ccall libaeron.aeron_image_poll(image::Ptr{aeron_image_t}, handler::aeron_fragment_handler_t, clientd::Ptr{Cvoid}, fragment_limit::Csize_t)::Cint
end

"""
    aeron_image_controlled_poll(image, handler, clientd, fragment_limit)

Poll for new messages in a stream. If new messages are found beyond the last consumed position then they will be delivered to the handler up to a limited number of fragments as specified. <p> Use a controlled fragment assembler to assemble messages which span multiple fragments.

# Arguments
* `image`: to poll.
* `handler`: to which message fragments are delivered.
* `clientd`: to pass to the handler.
* `fragment_limit`: for the number of fragments to be consumed during one polling operation.
# Returns
the number of fragments that have been consumed or -1 for error.
### Prototype
```c
int aeron_image_controlled_poll( aeron_image_t *image, aeron_controlled_fragment_handler_t handler, void *clientd, size_t fragment_limit);
```
"""
function aeron_image_controlled_poll(image, handler, clientd, fragment_limit)
    @ccall libaeron.aeron_image_controlled_poll(image::Ptr{aeron_image_t}, handler::aeron_controlled_fragment_handler_t, clientd::Ptr{Cvoid}, fragment_limit::Csize_t)::Cint
end

"""
    aeron_image_bounded_poll(image, handler, clientd, limit_position, fragment_limit)

Poll for new messages in a stream. If new messages are found beyond the last consumed position then they will be delivered to the handler up to a limited number of fragments as specified or the maximum position specified. <p> Use a fragment assembler to assemble messages which span multiple fragments.

# Arguments
* `image`: to poll.
* `handler`: to which message fragments are delivered.
* `clientd`: to pass to the handler.
* `limit_position`: to consume messages up to.
* `fragment_limit`: for the number of fragments to be consumed during one polling operation.
# Returns
the number of fragments that have been consumed or -1 for error.
### Prototype
```c
int aeron_image_bounded_poll( aeron_image_t *image, aeron_fragment_handler_t handler, void *clientd, int64_t limit_position, size_t fragment_limit);
```
"""
function aeron_image_bounded_poll(image, handler, clientd, limit_position, fragment_limit)
    @ccall libaeron.aeron_image_bounded_poll(image::Ptr{aeron_image_t}, handler::aeron_fragment_handler_t, clientd::Ptr{Cvoid}, limit_position::Int64, fragment_limit::Csize_t)::Cint
end

"""
    aeron_image_bounded_controlled_poll(image, handler, clientd, limit_position, fragment_limit)

Poll for new messages in a stream. If new messages are found beyond the last consumed position then they will be delivered to the handler up to a limited number of fragments as specified or the maximum position specified. <p> Use a controlled fragment assembler to assemble messages which span multiple fragments.

# Arguments
* `image`: to poll.
* `handler`: to which message fragments are delivered.
* `clientd`: to pass to the handler.
* `limit_position`: to consume messages up to.
* `fragment_limit`: for the number of fragments to be consumed during one polling operation.
# Returns
the number of fragments that have been consumed or -1 for error.
### Prototype
```c
int aeron_image_bounded_controlled_poll( aeron_image_t *image, aeron_controlled_fragment_handler_t handler, void *clientd, int64_t limit_position, size_t fragment_limit);
```
"""
function aeron_image_bounded_controlled_poll(image, handler, clientd, limit_position, fragment_limit)
    @ccall libaeron.aeron_image_bounded_controlled_poll(image::Ptr{aeron_image_t}, handler::aeron_controlled_fragment_handler_t, clientd::Ptr{Cvoid}, limit_position::Int64, fragment_limit::Csize_t)::Cint
end

"""
    aeron_image_controlled_peek(image, initial_position, handler, clientd, limit_position)

Peek for new messages in a stream by scanning forward from an initial position. If new messages are found then they will be delivered to the handler up to a limited position. <p> Use a controlled fragment assembler to assemble messages which span multiple fragments. Scans must also start at the beginning of a message so that the assembler is reset.

# Arguments
* `image`: to peek.
* `initial_position`: from which to peek forward.
* `handler`: to which message fragments are delivered.
* `clientd`: to pass to the handler.
* `limit_position`: up to which can be scanned.
# Returns
the resulting position after the scan terminates which is a complete message or -1 for error.
### Prototype
```c
int64_t aeron_image_controlled_peek( aeron_image_t *image, int64_t initial_position, aeron_controlled_fragment_handler_t handler, void *clientd, int64_t limit_position);
```
"""
function aeron_image_controlled_peek(image, initial_position, handler, clientd, limit_position)
    @ccall libaeron.aeron_image_controlled_peek(image::Ptr{aeron_image_t}, initial_position::Int64, handler::aeron_controlled_fragment_handler_t, clientd::Ptr{Cvoid}, limit_position::Int64)::Int64
end

"""
    aeron_image_block_poll(image, handler, clientd, block_length_limit)

Poll for new messages in a stream. If new messages are found beyond the last consumed position then they will be delivered to the handler up to a limited number of bytes. <p> A scan will terminate if a padding frame is encountered. If first frame in a scan is padding then a block for the padding is notified. If the padding comes after the first frame in a scan then the scan terminates at the offset the padding frame begins. Padding frames are delivered singularly in a block. <p> Padding frames may be for a greater range than the limit offset but only the header needs to be valid so relevant length of the frame is data header length.

# Arguments
* `image`: to poll.
* `handler`: to which block is delivered.
* `clientd`: to pass to the handler.
* `block_length_limit`: up to which a block may be in length.
# Returns
the number of bytes that have been consumed or -1 for error.
### Prototype
```c
int aeron_image_block_poll( aeron_image_t *image, aeron_block_handler_t handler, void *clientd, size_t block_length_limit);
```
"""
function aeron_image_block_poll(image, handler, clientd, block_length_limit)
    @ccall libaeron.aeron_image_block_poll(image::Ptr{aeron_image_t}, handler::aeron_block_handler_t, clientd::Ptr{Cvoid}, block_length_limit::Csize_t)::Cint
end

"""
    aeron_image_is_closed(image)

### Prototype
```c
bool aeron_image_is_closed(aeron_image_t *image);
```
"""
function aeron_image_is_closed(image)
    @ccall libaeron.aeron_image_is_closed(image::Ptr{aeron_image_t})::Bool
end

"""
    aeron_image_fragment_assembler_create(assembler, delegate, delegate_clientd)

Create an image fragment assembler for use with a single image.

# Arguments
* `assembler`: to be set when created successfully.
* `delegate`: to call on completed.
* `delegate_clientd`: to pass to delegate handler.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_image_fragment_assembler_create( aeron_image_fragment_assembler_t **assembler, aeron_fragment_handler_t delegate, void *delegate_clientd);
```
"""
function aeron_image_fragment_assembler_create(assembler, delegate, delegate_clientd)
    @ccall libaeron.aeron_image_fragment_assembler_create(assembler::Ptr{Ptr{aeron_image_fragment_assembler_t}}, delegate::aeron_fragment_handler_t, delegate_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_image_fragment_assembler_delete(assembler)

Delete an image fragment assembler.

# Arguments
* `assembler`: to delete.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_image_fragment_assembler_delete(aeron_image_fragment_assembler_t *assembler);
```
"""
function aeron_image_fragment_assembler_delete(assembler)
    @ccall libaeron.aeron_image_fragment_assembler_delete(assembler::Ptr{aeron_image_fragment_assembler_t})::Cint
end

"""
    aeron_image_fragment_assembler_handler(clientd, buffer, length, header)

Handler function to be passed for handling fragment assembly.

# Arguments
* `clientd`: passed in the poll call (must be a [`aeron_image_fragment_assembler_t`](@ref))
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
### Prototype
```c
void aeron_image_fragment_assembler_handler( void *clientd, const uint8_t *buffer, size_t length, aeron_header_t *header);
```
"""
function aeron_image_fragment_assembler_handler(clientd, buffer, length, header)
    @ccall libaeron.aeron_image_fragment_assembler_handler(clientd::Ptr{Cvoid}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})::Cvoid
end

"""
    aeron_image_controlled_fragment_assembler_create(assembler, delegate, delegate_clientd)

Create an image controlled fragment assembler for use with a single image.

# Arguments
* `assembler`: to be set when created successfully.
* `delegate`: to call on completed
* `delegate_clientd`: to pass to delegate handler.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_image_controlled_fragment_assembler_create( aeron_image_controlled_fragment_assembler_t **assembler, aeron_controlled_fragment_handler_t delegate, void *delegate_clientd);
```
"""
function aeron_image_controlled_fragment_assembler_create(assembler, delegate, delegate_clientd)
    @ccall libaeron.aeron_image_controlled_fragment_assembler_create(assembler::Ptr{Ptr{aeron_image_controlled_fragment_assembler_t}}, delegate::aeron_controlled_fragment_handler_t, delegate_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_image_controlled_fragment_assembler_delete(assembler)

Delete an image controlled fragment assembler.

# Arguments
* `assembler`: to delete.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_image_controlled_fragment_assembler_delete(aeron_image_controlled_fragment_assembler_t *assembler);
```
"""
function aeron_image_controlled_fragment_assembler_delete(assembler)
    @ccall libaeron.aeron_image_controlled_fragment_assembler_delete(assembler::Ptr{aeron_image_controlled_fragment_assembler_t})::Cint
end

"""
    aeron_image_controlled_fragment_assembler_handler(clientd, buffer, length, header)

Handler function to be passed for handling fragment assembly.

# Arguments
* `clientd`: passed in the poll call (must be a [`aeron_image_controlled_fragment_assembler_t`](@ref))
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
# Returns
The action to be taken with regard to the stream position after the callback.
### Prototype
```c
aeron_controlled_fragment_handler_action_t aeron_image_controlled_fragment_assembler_handler( void *clientd, const uint8_t *buffer, size_t length, aeron_header_t *header);
```
"""
function aeron_image_controlled_fragment_assembler_handler(clientd, buffer, length, header)
    @ccall libaeron.aeron_image_controlled_fragment_assembler_handler(clientd::Ptr{Cvoid}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})::aeron_controlled_fragment_handler_action_t
end

"""
    aeron_fragment_assembler_create(assembler, delegate, delegate_clientd)

Create a fragment assembler for use with a subscription.

# Arguments
* `assembler`: to be set when created successfully.
* `delegate`: to call on completed
* `delegate_clientd`: to pass to delegate handler.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_fragment_assembler_create( aeron_fragment_assembler_t **assembler, aeron_fragment_handler_t delegate, void *delegate_clientd);
```
"""
function aeron_fragment_assembler_create(assembler, delegate, delegate_clientd)
    @ccall libaeron.aeron_fragment_assembler_create(assembler::Ptr{Ptr{aeron_fragment_assembler_t}}, delegate::aeron_fragment_handler_t, delegate_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_fragment_assembler_delete(assembler)

Delete a fragment assembler.

# Arguments
* `assembler`: to delete.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_fragment_assembler_delete(aeron_fragment_assembler_t *assembler);
```
"""
function aeron_fragment_assembler_delete(assembler)
    @ccall libaeron.aeron_fragment_assembler_delete(assembler::Ptr{aeron_fragment_assembler_t})::Cint
end

"""
    aeron_fragment_assembler_handler(clientd, buffer, length, header)

Handler function to be passed for handling fragment assembly.

# Arguments
* `clientd`: passed in the poll call (must be a [`aeron_fragment_assembler_t`](@ref))
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
### Prototype
```c
void aeron_fragment_assembler_handler( void *clientd, const uint8_t *buffer, size_t length, aeron_header_t *header);
```
"""
function aeron_fragment_assembler_handler(clientd, buffer, length, header)
    @ccall libaeron.aeron_fragment_assembler_handler(clientd::Ptr{Cvoid}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})::Cvoid
end

"""
    aeron_controlled_fragment_assembler_create(assembler, delegate, delegate_clientd)

Create a controlled fragment assembler for use with a subscription.

# Arguments
* `assembler`: to be set when created successfully.
* `delegate`: to call on completed
* `delegate_clientd`: to pass to delegate handler.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_controlled_fragment_assembler_create( aeron_controlled_fragment_assembler_t **assembler, aeron_controlled_fragment_handler_t delegate, void *delegate_clientd);
```
"""
function aeron_controlled_fragment_assembler_create(assembler, delegate, delegate_clientd)
    @ccall libaeron.aeron_controlled_fragment_assembler_create(assembler::Ptr{Ptr{aeron_controlled_fragment_assembler_t}}, delegate::aeron_controlled_fragment_handler_t, delegate_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_controlled_fragment_assembler_delete(assembler)

Delete a controlled fragment assembler.

# Arguments
* `assembler`: to delete.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_controlled_fragment_assembler_delete(aeron_controlled_fragment_assembler_t *assembler);
```
"""
function aeron_controlled_fragment_assembler_delete(assembler)
    @ccall libaeron.aeron_controlled_fragment_assembler_delete(assembler::Ptr{aeron_controlled_fragment_assembler_t})::Cint
end

"""
    aeron_controlled_fragment_assembler_handler(clientd, buffer, length, header)

Handler function to be passed for handling fragment assembly.

# Arguments
* `clientd`: passed in the poll call (must be a [`aeron_controlled_fragment_assembler_t`](@ref))
* `buffer`: containing the data.
* `length`: of the data in bytes.
* `header`: representing the meta data for the data.
# Returns
The action to be taken with regard to the stream position after the callback.
### Prototype
```c
aeron_controlled_fragment_handler_action_t aeron_controlled_fragment_assembler_handler( void *clientd, const uint8_t *buffer, size_t length, aeron_header_t *header);
```
"""
function aeron_controlled_fragment_assembler_handler(clientd, buffer, length, header)
    @ccall libaeron.aeron_controlled_fragment_assembler_handler(clientd::Ptr{Cvoid}, buffer::Ptr{UInt8}, length::Csize_t, header::Ptr{aeron_header_t})::aeron_controlled_fragment_handler_action_t
end

"""
    aeron_counter_addr(counter)

Return a pointer to the counter value.

# Arguments
* `counter`: to pointer to.
# Returns
pointer to the counter value.
### Prototype
```c
int64_t *aeron_counter_addr(aeron_counter_t *counter);
```
"""
function aeron_counter_addr(counter)
    @ccall libaeron.aeron_counter_addr(counter::Ptr{aeron_counter_t})::Ptr{Int64}
end

"""
    aeron_counter_constants_stct

Configuration for a counter that does not change during it's lifetime.
"""
struct aeron_counter_constants_stct
    registration_id::Int64
    counter_id::Int32
end

"""
Configuration for a counter that does not change during it's lifetime.
"""
const aeron_counter_constants_t = aeron_counter_constants_stct

"""
    aeron_counter_constants(counter, constants)

Fill in a structure with the constants in use by a counter.

# Arguments
* `counter`: to get the constants for.
* `constants`: structure to fill in with the constants.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_counter_constants(aeron_counter_t *counter, aeron_counter_constants_t *constants);
```
"""
function aeron_counter_constants(counter, constants)
    @ccall libaeron.aeron_counter_constants(counter::Ptr{aeron_counter_t}, constants::Ptr{aeron_counter_constants_t})::Cint
end

"""
    aeron_counter_close(counter, on_close_complete, on_close_complete_clientd)

Asynchronously close the counter.

# Arguments
* `counter`: to close.
# Returns
0 for success or -1 for error.
### Prototype
```c
int aeron_counter_close( aeron_counter_t *counter, aeron_notification_t on_close_complete, void *on_close_complete_clientd);
```
"""
function aeron_counter_close(counter, on_close_complete, on_close_complete_clientd)
    @ccall libaeron.aeron_counter_close(counter::Ptr{aeron_counter_t}, on_close_complete::aeron_notification_t, on_close_complete_clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_counter_is_closed(counter)

Check if the counter is closed

# Arguments
* `counter`: to check
# Returns
true if closed, false otherwise.
### Prototype
```c
bool aeron_counter_is_closed(aeron_counter_t *counter);
```
"""
function aeron_counter_is_closed(counter)
    @ccall libaeron.aeron_counter_is_closed(counter::Ptr{aeron_counter_t})::Bool
end

"""
    aeron_version_full()

Return full version and build string.

# Returns
full version and build string.
### Prototype
```c
const char *aeron_version_full(void);
```
"""
function aeron_version_full()
    @ccall libaeron.aeron_version_full()::Cstring
end

"""
    aeron_version_text()

Return version text.

# Returns
version text.
### Prototype
```c
const char *aeron_version_text(void);
```
"""
function aeron_version_text()
    @ccall libaeron.aeron_version_text()::Cstring
end

"""
    aeron_version_major()

Return major version number.

# Returns
major version number.
### Prototype
```c
int aeron_version_major(void);
```
"""
function aeron_version_major()
    @ccall libaeron.aeron_version_major()::Cint
end

"""
    aeron_version_minor()

Return minor version number.

# Returns
minor version number.
### Prototype
```c
int aeron_version_minor(void);
```
"""
function aeron_version_minor()
    @ccall libaeron.aeron_version_minor()::Cint
end

"""
    aeron_version_patch()

Return patch version number.

# Returns
patch version number.
### Prototype
```c
int aeron_version_patch(void);
```
"""
function aeron_version_patch()
    @ccall libaeron.aeron_version_patch()::Cint
end

"""
    aeron_version_gitsha()

Return the git sha for the current build.

# Returns
git version
### Prototype
```c
const char *aeron_version_gitsha(void);
```
"""
function aeron_version_gitsha()
    @ccall libaeron.aeron_version_gitsha()::Cstring
end

# typedef int64_t ( * aeron_clock_func_t ) ( void )
"""
Clock function used by aeron.
"""
const aeron_clock_func_t = Ptr{Cvoid}

"""
    aeron_nano_clock()

Return time in nanoseconds for machine. Is not wall clock time.

# Returns
nanoseconds since epoch for machine.
### Prototype
```c
int64_t aeron_nano_clock(void);
```
"""
function aeron_nano_clock()
    @ccall libaeron.aeron_nano_clock()::Int64
end

"""
    aeron_epoch_clock()

Return time in milliseconds since epoch. Is wall clock time.

# Returns
milliseconds since epoch.
### Prototype
```c
int64_t aeron_epoch_clock(void);
```
"""
function aeron_epoch_clock()
    @ccall libaeron.aeron_epoch_clock()::Int64
end

# typedef void ( * aeron_log_func_t ) ( const char * )
"""
Function to return logging information.
"""
const aeron_log_func_t = Ptr{Cvoid}

"""
    aeron_is_driver_active(dirname, timeout_ms, log_func)

Determine if an aeron driver is using a given aeron directory.

# Arguments
* `dirname`: for aeron directory
* `timeout_ms`: to use to determine activity for aeron directory
* `log_func`: to call during activity check to log diagnostic information.
# Returns
true for active driver or false for no active driver.
### Prototype
```c
bool aeron_is_driver_active(const char *dirname, int64_t timeout_ms, aeron_log_func_t log_func);
```
"""
function aeron_is_driver_active(dirname, timeout_ms, log_func)
    @ccall libaeron.aeron_is_driver_active(dirname::Cstring, timeout_ms::Int64, log_func::aeron_log_func_t)::Bool
end

"""
    aeron_properties_buffer_load(buffer)

Load properties from a string containing name=value pairs and set appropriate environment variables for the process so that subsequent calls to aeron\\_driver\\_context\\_init will use those values.

# Arguments
* `buffer`: containing properties and values.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_properties_buffer_load(const char *buffer);
```
"""
function aeron_properties_buffer_load(buffer)
    @ccall libaeron.aeron_properties_buffer_load(buffer::Cstring)::Cint
end

"""
    aeron_properties_file_load(filename)

Load properties file and set appropriate environment variables for the process so that subsequent calls to aeron\\_driver\\_context\\_init will use those values.

# Arguments
* `filename`: to load.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_properties_file_load(const char *filename);
```
"""
function aeron_properties_file_load(filename)
    @ccall libaeron.aeron_properties_file_load(filename::Cstring)::Cint
end

"""
    aeron_properties_http_load(url)

Load properties from HTTP URL and set environment variables for the process so that subsequent calls to aeron\\_driver\\_context\\_init will use those values.

# Arguments
* `url`: to attempt to retrieve and load.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_properties_http_load(const char *url);
```
"""
function aeron_properties_http_load(url)
    @ccall libaeron.aeron_properties_http_load(url::Cstring)::Cint
end

"""
    aeron_properties_load(url_or_filename)

Load properties based on URL or filename. If string contains file or http URL, it will attempt to load properties from a file or http as indicated. If not a URL, then it will try to load the string as a filename.

# Arguments
* `url_or_filename`: to load properties from.
# Returns
0 for success and -1 for error.
### Prototype
```c
int aeron_properties_load(const char *url_or_filename);
```
"""
function aeron_properties_load(url_or_filename)
    @ccall libaeron.aeron_properties_load(url_or_filename::Cstring)::Cint
end

"""
    aeron_errcode()

Return current aeron error code (errno) for calling thread.

# Returns
aeron error code for calling thread.
### Prototype
```c
int aeron_errcode(void);
```
"""
function aeron_errcode()
    @ccall libaeron.aeron_errcode()::Cint
end

"""
    aeron_errmsg()

Return the current aeron error message for calling thread.

# Returns
aeron error message for calling thread.
### Prototype
```c
const char *aeron_errmsg(void);
```
"""
function aeron_errmsg()
    @ccall libaeron.aeron_errmsg()::Cstring
end

"""
    aeron_default_path(path, path_length)

Get the default path used by the Aeron media driver.

# Arguments
* `path`: buffer to store the path.
* `path_length`: space available in the buffer
# Returns
-1 if there is an issue or the number of bytes written to path excluding the terminator <code>\\0</code>. If this is equal to or greater than the path\\_length then the path has been truncated.
### Prototype
```c
int aeron_default_path(char *path, size_t path_length);
```
"""
function aeron_default_path(path, path_length)
    @ccall libaeron.aeron_default_path(path::Cstring, path_length::Csize_t)::Cint
end

"""
    aeron_async_add_counter_get_registration_id(add_counter)

Gets the registration id for addition of the counter. Note that using this after a call to poll the succeeds or errors is undefined behaviour. As the async\\_add\\_counter\\_t may have been freed.

# Arguments
* `add_counter`: used to check for completion.
# Returns
registration id for the counter.
### Prototype
```c
int64_t aeron_async_add_counter_get_registration_id(aeron_async_add_counter_t *add_counter);
```
"""
function aeron_async_add_counter_get_registration_id(add_counter)
    @ccall libaeron.aeron_async_add_counter_get_registration_id(add_counter::Ptr{aeron_async_add_counter_t})::Int64
end

"""
    aeron_async_add_publication_get_registration_id(add_publication)

Gets the registration id for addition of the publication. Note that using this after a call to poll the succeeds or errors is undefined behaviour. As the async\\_add\\_publication\\_t may have been freed.

# Arguments
* `add_publication`: used to check for completion.
# Returns
registration id for the publication.
### Prototype
```c
int64_t aeron_async_add_publication_get_registration_id(aeron_async_add_publication_t *add_publication);
```
"""
function aeron_async_add_publication_get_registration_id(add_publication)
    @ccall libaeron.aeron_async_add_publication_get_registration_id(add_publication::Ptr{aeron_async_add_publication_t})::Int64
end

"""
    aeron_async_add_exclusive_exclusive_publication_get_registration_id(add_exclusive_publication)

Gets the registration id for addition of the exclusive\\_publication. Note that using this after a call to poll the succeeds or errors is undefined behaviour. As the async\\_add\\_exclusive\\_publication\\_t may have been freed.

# Arguments
* `add_exclusive_publication`: used to check for completion.
# Returns
registration id for the exclusive\\_publication.
### Prototype
```c
int64_t aeron_async_add_exclusive_exclusive_publication_get_registration_id( aeron_async_add_exclusive_publication_t *add_exclusive_publication);
```
"""
function aeron_async_add_exclusive_exclusive_publication_get_registration_id(add_exclusive_publication)
    @ccall libaeron.aeron_async_add_exclusive_exclusive_publication_get_registration_id(add_exclusive_publication::Ptr{aeron_async_add_exclusive_publication_t})::Int64
end

"""
    aeron_async_add_subscription_get_registration_id(add_subscription)

Gets the registration id for addition of the subscription. Note that using this after a call to poll the succeeds or errors is undefined behaviour. As the async\\_add\\_subscription\\_t may have been freed.

# Arguments
* `add_subscription`: used to check for completion.
# Returns
registration id for the subscription.
### Prototype
```c
int64_t aeron_async_add_subscription_get_registration_id(aeron_async_add_subscription_t *add_subscription);
```
"""
function aeron_async_add_subscription_get_registration_id(add_subscription)
    @ccall libaeron.aeron_async_add_subscription_get_registration_id(add_subscription::Ptr{aeron_async_add_subscription_t})::Int64
end

"""
    aeron_async_destination_get_registration_id(async_destination)

Gets the registration\\_id for the destination command supplied. Note that this is the correlation\\_id used for the specified destination command, not the registration\\_id for the original parent resource (publication, subscription).

# Arguments
* `async_destination`: tracking the current destination command.
# Returns
correlation\\_id sent to driver.
### Prototype
```c
int64_t aeron_async_destination_get_registration_id(aeron_async_destination_t *async_destination);
```
"""
function aeron_async_destination_get_registration_id(async_destination)
    @ccall libaeron.aeron_async_destination_get_registration_id(async_destination::Ptr{aeron_async_destination_t})::Int64
end

"""
    aeron_context_request_driver_termination(directory, token_buffer, token_length)

Request the media driver terminates operation and closes all resources.

# Arguments
* `directory`: in which the media driver is running.
* `token_buffer`: containing the authentication token confirming the client is allowed to terminate the driver.
* `token_length`: of the token in the buffer.
# Returns

### Prototype
```c
int aeron_context_request_driver_termination(const char *directory, const uint8_t *token_buffer, size_t token_length);
```
"""
function aeron_context_request_driver_termination(directory, token_buffer, token_length)
    @ccall libaeron.aeron_context_request_driver_termination(directory::Cstring, token_buffer::Ptr{UInt8}, token_length::Csize_t)::Cint
end

mutable struct aeron_cnc_stct end

const aeron_cnc_t = aeron_cnc_stct

struct aeron_cnc_constants_stct
    data::NTuple{48, UInt8}
end

function Base.getproperty(x::Ptr{aeron_cnc_constants_stct}, f::Symbol)
    f === :cnc_version && return Ptr{Int32}(x + 0)
    f === :to_driver_buffer_length && return Ptr{Int32}(x + 4)
    f === :to_clients_buffer_length && return Ptr{Int32}(x + 8)
    f === :counter_metadata_buffer_length && return Ptr{Int32}(x + 12)
    f === :counter_values_buffer_length && return Ptr{Int32}(x + 16)
    f === :error_log_buffer_length && return Ptr{Int32}(x + 20)
    f === :client_liveness_timeout && return Ptr{Int64}(x + 24)
    f === :start_timestamp && return Ptr{Int64}(x + 32)
    f === :pid && return Ptr{Int64}(x + 40)
    return getfield(x, f)
end

function Base.getproperty(x::aeron_cnc_constants_stct, f::Symbol)
    r = Ref{aeron_cnc_constants_stct}(x)
    ptr = Base.unsafe_convert(Ptr{aeron_cnc_constants_stct}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{aeron_cnc_constants_stct}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const aeron_cnc_constants_t = aeron_cnc_constants_stct

"""
    aeron_cnc_init(aeron_cnc, base_path, timeout_ms)

Initialise an aeron\\_cnc, which gives user level access to the command and control file used to communicate with the media driver. Will wait until the media driver has loaded and the cnc file is created, up to timeout\\_ms. Use a value of 0 for a non-blocking initialisation.

# Arguments
* `aeron_cnc`: to hold the loaded aeron\\_cnc
* `base_path`: media driver's base path
* `timeout_ms`: Number of milliseconds to wait before timing out.
# Returns
0 on success, -1 on failure.
### Prototype
```c
int aeron_cnc_init(aeron_cnc_t **aeron_cnc, const char *base_path, int64_t timeout_ms);
```
"""
function aeron_cnc_init(aeron_cnc, base_path, timeout_ms)
    @ccall libaeron.aeron_cnc_init(aeron_cnc::Ptr{Ptr{aeron_cnc_t}}, base_path::Cstring, timeout_ms::Int64)::Cint
end

"""
    aeron_cnc_constants(aeron_cnc, constants)

Fetch the sets of constant values associated with this command and control file.

# Arguments
* `aeron_cnc`: to query
* `constants`: user supplied structure to hold return values.
# Returns
0 on success, -1 on failure.
### Prototype
```c
int aeron_cnc_constants(aeron_cnc_t *aeron_cnc, aeron_cnc_constants_t *constants);
```
"""
function aeron_cnc_constants(aeron_cnc, constants)
    @ccall libaeron.aeron_cnc_constants(aeron_cnc::Ptr{aeron_cnc_t}, constants::Ptr{aeron_cnc_constants_t})::Cint
end

"""
    aeron_cnc_filename(aeron_cnc)

Get the current file name of the cnc file.

# Arguments
* `aeron_cnc`: to query
# Returns
name of the cnc file
### Prototype
```c
const char *aeron_cnc_filename(aeron_cnc_t *aeron_cnc);
```
"""
function aeron_cnc_filename(aeron_cnc)
    @ccall libaeron.aeron_cnc_filename(aeron_cnc::Ptr{aeron_cnc_t})::Cstring
end

"""
    aeron_cnc_to_driver_heartbeat(aeron_cnc)

Gets the timestamp of the last heartbeat sent to the media driver from any client.

# Arguments
* `aeron_cnc`: to query
# Returns
last heartbeat timestamp in ms.
### Prototype
```c
int64_t aeron_cnc_to_driver_heartbeat(aeron_cnc_t *aeron_cnc);
```
"""
function aeron_cnc_to_driver_heartbeat(aeron_cnc)
    @ccall libaeron.aeron_cnc_to_driver_heartbeat(aeron_cnc::Ptr{aeron_cnc_t})::Int64
end

# typedef void ( * aeron_error_log_reader_func_t ) ( int32_t observation_count , int64_t first_observation_timestamp , int64_t last_observation_timestamp , const char * error , size_t error_length , void * clientd )
const aeron_error_log_reader_func_t = Ptr{Cvoid}

"""
    aeron_cnc_error_log_read(aeron_cnc, callback, clientd, since_timestamp)

Reads the current error log for this driver.

# Arguments
* `aeron_cnc`: to query
* `callback`: called for every distinct error observation
* `clientd`: client data to be passed to the callback
* `since_timestamp`: only return errors after this timestamp (0 returns all)
# Returns
the number of distinct errors seen
### Prototype
```c
size_t aeron_cnc_error_log_read( aeron_cnc_t *aeron_cnc, aeron_error_log_reader_func_t callback, void *clientd, int64_t since_timestamp);
```
"""
function aeron_cnc_error_log_read(aeron_cnc, callback, clientd, since_timestamp)
    @ccall libaeron.aeron_cnc_error_log_read(aeron_cnc::Ptr{aeron_cnc_t}, callback::aeron_error_log_reader_func_t, clientd::Ptr{Cvoid}, since_timestamp::Int64)::Csize_t
end

"""
    aeron_cnc_counters_reader(aeron_cnc)

Gets a counters reader for this command and control file. This does not need to be closed manually, resources are tied to the instance of aeron\\_cnc.

# Arguments
* `aeron_cnc`: to query
# Returns
pointer to a counters reader.
### Prototype
```c
aeron_counters_reader_t *aeron_cnc_counters_reader(aeron_cnc_t *aeron_cnc);
```
"""
function aeron_cnc_counters_reader(aeron_cnc)
    @ccall libaeron.aeron_cnc_counters_reader(aeron_cnc::Ptr{aeron_cnc_t})::Ptr{aeron_counters_reader_t}
end

# typedef void ( * aeron_loss_reporter_read_entry_func_t ) ( void * clientd , int64_t observation_count , int64_t total_bytes_lost , int64_t first_observation_timestamp , int64_t last_observation_timestamp , int32_t session_id , int32_t stream_id , const char * channel , int32_t channel_length , const char * source , int32_t source_length )
const aeron_loss_reporter_read_entry_func_t = Ptr{Cvoid}

"""
    aeron_cnc_loss_reporter_read(aeron_cnc, entry_func, clientd)

Read all of the data loss observations from the report in the same media driver instances as the cnc file.

# Arguments
* `aeron_cnc`: to query
* `entry_func`: callback for each observation found
* `clientd`: client data to be passed to the callback.
# Returns
-1 on failure, number of observations on success (could be 0).
### Prototype
```c
int aeron_cnc_loss_reporter_read( aeron_cnc_t *aeron_cnc, aeron_loss_reporter_read_entry_func_t entry_func, void *clientd);
```
"""
function aeron_cnc_loss_reporter_read(aeron_cnc, entry_func, clientd)
    @ccall libaeron.aeron_cnc_loss_reporter_read(aeron_cnc::Ptr{aeron_cnc_t}, entry_func::aeron_loss_reporter_read_entry_func_t, clientd::Ptr{Cvoid})::Cint
end

"""
    aeron_cnc_close(aeron_cnc)

Closes the instance of the aeron cnc and frees its resources.

# Arguments
* `aeron_cnc`: to close
### Prototype
```c
void aeron_cnc_close(aeron_cnc_t *aeron_cnc);
```
"""
function aeron_cnc_close(aeron_cnc)
    @ccall libaeron.aeron_cnc_close(aeron_cnc::Ptr{aeron_cnc_t})::Cvoid
end

const AERON_NULL_VALUE = -1

const AERON_CLIENT_ERROR_DRIVER_TIMEOUT = -1000

const AERON_CLIENT_ERROR_CLIENT_TIMEOUT = -1001

const AERON_CLIENT_ERROR_CONDUCTOR_SERVICE_TIMEOUT = -1002

const AERON_CLIENT_ERROR_BUFFER_FULL = -1003

const AERON_CLIENT_MAX_LOCAL_ADDRESS_STR_LEN = 64

const AERON_DIR_ENV_VAR = "AERON_DIR"

const AERON_DRIVER_TIMEOUT_ENV_VAR = "AERON_DRIVER_TIMEOUT"

const AERON_CLIENT_RESOURCE_LINGER_DURATION_ENV_VAR = "AERON_CLIENT_RESOURCE_LINGER_DURATION"

const AERON_CLIENT_IDLE_SLEEP_DURATION_ENV_VAR = "AERON_CLIENT_IDLE_SLEEP_DURATION"

const AERON_CLIENT_PRE_TOUCH_MAPPED_MEMORY_ENV_VAR = "AERON_CLIENT_PRE_TOUCH_MAPPED_MEMORY"

const AERON_CLIENT_NAME_ENV_VAR = "AERON_CLIENT_NAME"

const AERON_AGENT_ON_START_FUNCTION_ENV_VAR = "AERON_AGENT_ON_START_FUNCTION"

const AERON_COUNTER_CACHE_LINE_LENGTH = Cuint(64)

const AERON_COUNTER_MAX_CLIENT_NAME_LENGTH = 100

const AERON_COUNTER_RECORD_UNUSED = 0

const AERON_COUNTER_RECORD_ALLOCATED = 1

const AERON_COUNTER_RECORD_RECLAIMED = -1

const AERON_COUNTER_REGISTRATION_ID_DEFAULT = INT64_C(0)

const AERON_COUNTER_NOT_FREE_TO_REUSE = INT64_MAX

const AERON_COUNTER_OWNER_ID_DEFAULT = INT64_C(0)

const AERON_COUNTER_REFERENCE_ID_DEFAULT = INT64_C(0)

const AERON_NULL_COUNTER_ID = -1

const AERON_PUBLICATION_NOT_CONNECTED = -(Clong(1))

const AERON_PUBLICATION_BACK_PRESSURED = -(Clong(2))

const AERON_PUBLICATION_ADMIN_ACTION = -(Clong(3))

const AERON_PUBLICATION_CLOSED = -(Clong(4))

const AERON_PUBLICATION_MAX_POSITION_EXCEEDED = -(Clong(5))

const AERON_PUBLICATION_ERROR = -(Clong(6))

# exports
const PREFIXES = ["aeron_", "AERON_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
