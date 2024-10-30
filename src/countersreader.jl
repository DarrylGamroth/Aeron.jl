struct CountersReader
    counters_reader::Ptr{aeron_counters_reader_t}
    CountersReader(c::Client) = new(aeron_counters_reader(c.client))
end

@enumx CounterState begin
    RECORD_UNUSED = AERON_COUNTER_RECORD_UNUSED
    RECORD_ALLOCATED = AERON_COUNTER_RECORD_ALLOCATED
    RECORD_RECLAIMED = AERON_COUNTER_RECORD_RECLAIMED
end

struct CounterForEachFunction{T<:Function,C}
    func::T
    clientd::C
end

function counter_foreach_wrapper(value, id, type_id, key, key_length, label, label_length, clientd)
    clientd.func(value, id, type_id, UnsafeArray(key, (Int64(key_length),)),
        StringView(UnsafeArray(label, (Int64(label_length),))), clientd.clientd)
    nothing
end

function counter_foreach_cfunction(::T) where {T}
    @cfunction(counter_foreach_wrapper, Cvoid, (Int64, Int32, Int32, Ptr{UInt8}, Csize_t, Ptr{UInt8}, Csize_t, Ref{T}))
end

function counter_foreach(func::Function, c::CountersReader, clientd)
    f = CounterForEachFunction(func, clientd)
    aeron_counters_reader_foreach_counter(c.counters_reader, counter_foreach_cfunction(f), Ref(f))
end

function find_by_type_id_and_registration_id(c::CountersReader, type_id, registration_id)
    counter_id = aeron_counters_reader_find_by_type_id_and_registration_id(c.counters_reader, type_id, registration_id)
    if counter_id < 0
        return nothing
    end
    return counter_id
end

function max_counter_id(c::CountersReader)
    max_id = aeron_counters_reader_max_counter_id(c.counters_reader)
    if max_id < 0
        throwerror()
    end
    return max_id
end

function counter_value(c::CountersReader, counter_id)
    addr = aeron_counters_reader_addr(c.counters_reader, counter_id)
    unsafe_load(addr, :acquire)
end

function counter_registration_id(c::CountersReader, counter_id)
    registration_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_registration_id(c.counters_reader, counter_id, registration_id)
    if retval < 0
        throwerror()
    end
    return registration_id[]
end

function counter_owner_id(c::CountersReader, counter_id)
    owner_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_owner_id(c.counters_reader, counter_id, owner_id)
    if retval < 0
        throwerror()
    end
    return owner_id[]
end

function counter_reference_id(c::CountersReader, counter_id)
    reference_id = Ref{Int64}()
    retval = aeron_counters_reader_counter_reference_id(c.counters_reader, counter_id, reference_id)
    if retval < 0
        throwerror()
    end
    return reference_id[]
end

function counter_state(c::CountersReader, counter_id)
    state_ref = Ref{Int32}()
    retval = aeron_counters_reader_counter_state(c.counters_reader, counter_id, state_ref)
    if retval < 0
        throwerror()
    end
    state = state_ref[]
    return state == AERON_COUNTER_RECORD_UNUSED ? CounterState.RECORD_UNUSED :
           state == AERON_COUNTER_RECORD_ALLOCATED ? CounterState.RECORD_ALLOCATED :
           state == AERON_COUNTER_RECORD_RECLAIMED ? CounterState.RECORD_RECLAIMED :
           throwerror()
end

function counter_type_id(c::CountersReader, counter_id)
    type_id = Ref{Int32}()
    retval = aeron_counters_reader_counter_type_id(c.counters_reader, counter_id, type_id)
    if retval < 0
        throwerror()
    end
    return type_id[]
end

function counter_label(c::CountersReader, counter_id)
    label = Vector{UInt8}(undef, 256)
    GC.@preserve label begin
        length = aeron_counters_reader_counter_label(c.counters_reader, counter_id, pointer(label), Base.length(label))
        if length < 0
            throwerror()
        end
        return String(view(label, 1:length))
    end
end

function free_for_reuse_deadline_ms(c::CountersReader)
    deadline = Ref{Int64}()
    retval = aeron_counters_reader_free_for_reuse_deadline_ms(c.counters_reader, deadline)
    if retval < 0
        throwerror()
    end
    return deadline[]
end
