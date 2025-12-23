## Goal
Add unit tests for the Julia Aeron client wrapper that validate wrapper behavior (construction, API wiring, callbacks, and lifecycle), without retesting Aeron protocol logic. Tests should use an embedded media driver.

## Scope
- Cover `src/client` APIs first (Aeron client, publication, subscription, counters, handlers, fragment assemblers, buffer claims, exceptions).
- Defer `src/archive` and `src/driver` tests to a later phase.
- Use patterns from C++ wrapper tests in `/home/dgamroth/workspaces/codex/aeron/aeron-client/src/test/cpp_wrapper` as reference for scenarios.

## Test Harness Plan
- Create `test/` with `runtests.jl` using `Test`.
- Add `test/support.jl` with reusable helpers:
  - `with_embedded_driver(f)` that starts `MediaDriver.launch_embedded` and ensures clean shutdown.
  - `with_client(f; driver)` that creates `Aeron.Context`, sets `aeron_dir!` to the driver dir, and yields a `Client`.
  - `wait_for` / `poll_for` loops with timeout (mirror `POLL_FOR` from C++ tests) using `time()`/`sleep(0)`/`yield()`.
  - `unique_channel(media)` helper for IPC/UDP channel strings so tests can run independently.
- Ensure tests clean up publications, subscriptions, counters, and drivers even on failure.

## Test Coverage Plan (Aeron Client)
1) **Version and default path**
   - `version`, `version_major/minor/patch`, `version_gitsha` return non-empty/valid values.
   - `default_path()` returns a non-empty string.

2) **Context configuration round-trips**
   - `aeron_dir!`, `driver_timeout_ms!`, `keepalive_internal_ns!`, `resource_linger_duration_ns!`,
     `idle_sleep_duration_ns!`, `pre_touch_mapped_memory!`, `free_for_reuse_deadline_ms!` set/get.
   - `use_conductor_agent_invoker!` toggles without error (no invoker usage required in Julia).

3) **Client lifecycle**
   - `Client(context)` opens and `isopen` is true; `close` marks it closed.
   - `client_id` is stable per client; `next_correlation_id` is monotonic.

4) **Publication/Subscription basic flow**
   - Create publication + subscription on the same channel and stream id.
   - `offer` sends message and `poll` receives it via `FragmentHandler`.
   - Validate `Header` fields (`stream_id`, `session_id`, `frame_length` basics) and payload content.

5) **ReservedValueSupplier and header reserved value**
   - Use `ReservedValueSupplier` in `offer` to set reserved value and verify in received header.

6) **BufferClaim**
   - Use `try_claim`, write payload into `buffer(BufferClaim)`, `commit`, and receive message.
   - Cover `abort` path (claim then abort and confirm no delivery).

7) **FragmentAssembler**
   - Send payload larger than `max_payload_length(publication)` to force fragmentation.
   - Use `FragmentAssembler` to reassemble and verify full payload is delivered once.

8) **ControlledFragmentHandler / ControlledFragmentAssembler**
   - Use `ControlledFragmentHandler` to `BREAK` after first fragment and confirm partial consumption.
   - Use `ControlledFragmentAssembler` with `COMMIT` to validate reassembly and controlled return code.

9) **Counters and CountersReader**
   - `add_counter` + `find_counter_by_type_id_and_registration_id`.
   - `counter_value`, `counter_registration_id`, `counter_owner_id`, `counter_reference_id`, `counter_state`.
   - `counter_foreach` enumerates the added counter and label.

10) **Error mapping**
   - Directly call `map_to_exception_and_throw` with representative error codes and assert exception type.

## Implementation Sequence
1) Add `test/support.jl` helpers and base driver/client setup.
2) Implement "Context + Client" tests to validate basic lifecycles.
3) Implement pub/sub flow, then extend to reserved values and buffer claims.
4) Add fragment assembler and controlled fragment tests (use helper for fragmentation payloads).
5) Add counters and exceptions tests.
6) Run tests locally, iterate on timeouts and cleanup until stable.

## Notes / Assumptions
- Tests will rely on `MediaDriver.launch_embedded` and set the client `aeron_dir` to the driver dir.
- Use timeouts (e.g., 5s) to keep tests deterministic; if CI is slow, make timeouts configurable.
- Keep channels unique to avoid collisions across test runs.
