"""
    struct CountersReader

Represents a reader for Aeron counters.

# Fields

- `counters_reader::Ptr{aeron_counters_reader_t}`: Pointer to the underlying Aeron counters reader structure.

"""
struct CountersReader
    counters_reader::Ptr{aeron_counters_reader_t}
    client::Client
end

"""
    CountersReader(c::Client) -> CountersReader

Creates a new `CountersReader` instance with the given Aeron client.

# Arguments

- `c::Client`: The Aeron client.

# Returns

- `CountersReader`: The new `CountersReader` instance.
"""
CountersReader(c::Client) = CountersReader(aeron_counters_reader(c.client), client)

"""
    @enumx CounterState

Enumeration of possible states for a counter.

# Values

- `RECORD_UNUSED = 0`: The counter record is unused.
- `RECORD_ALLOCATED = 1`: The counter record is allocated.
- `RECORD_RECLAIMED = -1`: The counter record is reclaimed.
"""
@enumx CounterState begin
    RECORD_UNUSED = AERON_COUNTER_RECORD_UNUSED
    RECORD_ALLOCATED = AERON_COUNTER_RECORD_ALLOCATED
    RECORD_RECLAIMED = AERON_COUNTER_RECORD_RECLAIMED
end

function counter_foreach_wrapper(value, id, type_id, key, key_length, label, label_length, (callback, arg))
    callback(value, id, type_id, UnsafeArray(key, (Int64(key_length),)),
        StringView(UnsafeArray(label, (Int64(label_length),))), arg)
    nothing
end

function counter_foreach_cfunction(::T) where {T}
    @cfunction(counter_foreach_wrapper, Cvoid, (Int64, Int32, Int32, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t, Ref{T}))
end

"""
    counter_foreach(func::Function, c::CountersReader, clientd) -> Nothing

Iterates over the counters in the `CountersReader` and calls the given function for each counter.

# Arguments

- `callback::Function`: The function to be called for each counter. The signature of the function is `function(value::Int64, id::Int32, type_id::Int32, key::AbstractVector{UInt8}, label::AbstractString, clientd::Any) -> Nothing`.
- `c::CountersReader`: The counters reader.
- `clientd=nothing`: Client data passed to the function.

# Returns

- `Nothing`: This function does not return a value.
"""
function counter_foreach(callback::Function, c::CountersReader, clientd=nothing)
    cb = (callback, clientd)
    aeron_counters_reader_foreach_counter(c.counters_reader, counter_foreach_cfunction(cb), Ref(cb))
end

"""
    find_counter_by_type_id_and_registration_id(c::CountersReader, type_id::Int32, registration_id::Int64) -> Union{Nothing, Int32}

Finds the counter ID by type ID and registration ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `type_id::Int32`: The type ID of the counter.
- `registration_id::Int64`: The registration ID of the counter.

# Returns

- `Union{Nothing, Int32}`: The counter ID if found, otherwise `nothing`.
"""
function find_counter_by_type_id_and_registration_id(c::CountersReader, type_id, registration_id)
    counter_id = aeron_counters_reader_find_by_type_id_and_registration_id(c.counters_reader, type_id, registration_id)
    if counter_id < 0
        return nothing
    end
    return counter_id
end

"""
    max_counter_id(c::CountersReader) -> Int32

Returns the maximum counter ID in the `CountersReader`.

# Arguments

- `c::CountersReader`: The counters reader.

# Returns

- `Int32`: The maximum counter ID.
"""
function max_counter_id(c::CountersReader)
    max_id = aeron_counters_reader_max_counter_id(c.counters_reader)
    if max_id < 0
        throwerror()
    end
    return max_id
end

"""
    counter_value(c::CountersReader, counter_id::Int32) -> Int64

Returns the value of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Int64`: The value of the counter.
"""
function counter_value(c::CountersReader, counter_id)
    addr = aeron_counters_reader_addr(c.counters_reader, counter_id)
    unsafe_load(addr, :acquire)
end

"""
    counter_registration_id(c::CountersReader, counter_id::Int32) -> Int64

Returns the registration ID of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Int64`: The registration ID of the counter.
"""
function counter_registration_id(c::CountersReader, counter_id)
    registration_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_registration_id(c.counters_reader, counter_id, registration_id)
    if retval < 0
        throwerror()
    end
    return registration_id[]
end

"""
    counter_owner_id(c::CountersReader, counter_id::Int32) -> Int64

Returns the owner ID of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Int64`: The owner ID of the counter.
"""
function counter_owner_id(c::CountersReader, counter_id)
    owner_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_owner_id(c.counters_reader, counter_id, owner_id)
    if retval < 0
        throwerror()
    end
    return owner_id[]
end

"""
    counter_reference_id(c::CountersReader, counter_id::Int32) -> Int64

Returns the reference ID of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Int64`: The reference ID of the counter.
"""
function counter_reference_id(c::CountersReader, counter_id)
    reference_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_reference_id(c.counters_reader, counter_id, reference_id)
    if retval < 0
        throwerror()
    end
    return reference_id[]
end

"""
    counter_state(c::CountersReader, counter_id::Int32) -> CounterState

Returns the state of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `CounterState`: The state of the counter.
"""
function counter_state(c::CountersReader, counter_id)
    state_ref = Ref{Int32}()
    retval = aeron_counters_reader_counter_state(c.counters_reader, counter_id, state_ref)
    if retval < 0
        throwerror()
    end
    return CounterState.T(state_ref[])
end

"""
    counter_type_id(c::CountersReader, counter_id::Int32) -> Int32

Returns the type ID of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Int32`: The type ID of the counter.
"""
function counter_type_id(c::CountersReader, counter_id)
    type_id = Ref{Int32}()
    retval = aeron_counters_reader_counter_type_id(c.counters_reader, counter_id, type_id)
    if retval < 0
        throwerror()
    end
    return type_id[]
end

"""
    counter_label(c::CountersReader, counter_id::Int32) -> String

Returns the label of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `String`: The label of the counter.
"""
function counter_label(c::CountersReader, counter_id)
    label = Vector{UInt8}(undef, 256)
    GC.@preserve label begin
        length = aeron_counters_reader_counter_label(c.counters_reader, counter_id, pointer(label), Base.length(label))
        if length < 0
            throwerror()
        end
        return String(label[1:length])
    end
end

"""
    counter_key(c::CountersReader, counter_id::Int32) -> Vector{UInt8}

Returns the key of the counter with the given ID.

# Arguments

- `c::CountersReader`: The counters reader.
- `counter_id::Int32`: The ID of the counter.

# Returns

- `Vector{UInt8}`: The key of the counter.
"""
function counter_key(c::CountersReader, counter_id)
    key = Vector{UInt8}(undef, 256)
    GC.@preserve key begin
        length = aeron_counters_reader_counter_key(c.counters_reader, counter_id, pointer(key), Base.length(key))
        if length < 0
            throwerror()
        end
        return key[1:length]
    end
end

"""
    free_for_reuse_deadline_ms(c::CountersReader) -> Int64

Returns the deadline in milliseconds for when a counter can be reused after being freed.

# Arguments

- `c::CountersReader`: The counters reader.

# Returns

- `Int64`: The deadline in milliseconds for when a counter can be reused.
"""
function free_for_reuse_deadline_ms(c::CountersReader)
    deadline = Ref{Int64}()
    retval = aeron_counters_reader_free_for_reuse_deadline_ms(c.counters_reader, deadline)
    if retval < 0
        throwerror()
    end
    return deadline[]
end
