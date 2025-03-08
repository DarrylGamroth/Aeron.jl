mutable struct ReplayMerge
    replay_merge::Ptr{aeron_archive_replay_merge_t}
    subscription::Aeron.Subscription
    archive::Archive

    function ReplayMerge(subscription::Aeron.Subscription, archive::Archive,
        replay_channel, replay_destination, live_destination, recording_id, start_position,
        merge_progress_timeout_ms=REPLAY_MERGE_PROGRESS_TIMEOUT_DEFAULT_MS)

        replay_merge = Ref{aeron_archive_replay_merge_t}(C_NULL)
        epoch_clock = round(Int64, time() * 1000)
        if aeron_archive_replay_merge_init(replay_merge, subscription.subscription,
            archive.archive, replay_channel, replay_destination, live_destination,
            recording_id, start_position, epoch_clock, merge_progress_timeout_ms) < 0
            Aeron.throwerror()
        end
        finalizer(new(replay_merge[], subscription, archive)) do r
            close(r)
        end
    end
end

function Base.close(r::ReplayMerge)
    if aeron_archive_replay_merge_close(r.replay_merge) < 0
        Aeron.throwerror()
    end
end

function poll(r::ReplayMerge, fragment_handler::Aeron.AbstractFragmentHandler, fragment_limit)
    GC.@preserve fragment_handler begin
        num_fragments = aeron_archive_replay_merge_poll(r.replay_merge,
            Aeron.on_fragment_cfunction(fragment_handler), Ref(fragment_handler), fragment_limit)
    end

    if num_fragments < 0
        Aeron.throwerror()
    end

    return num_fragments
end

function do_work(r::ReplayMerge)
    work_count = aeron_archive_replay_merge_do_work(r.replay_merge)

    if work_count < 0
        Aeron.throwerror()
    end

    return work_count
end

is_merged(r::ReplayMerge) = aeron_archive_replay_merge_is_merged(r.replay_merge)
has_failed(r::ReplayMerge) = aeron_archive_replay_merge_has_failed(r.replay_merge)
is_live_added(r::ReplayMerge) = aeron_archive_replay_merge_is_live_added(r.replay_merge)
