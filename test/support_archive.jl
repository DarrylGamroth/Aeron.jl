using Downloads
using Sockets

const ARCHIVE_VERSION = get(ENV, "AERON_ARCHIVE_VERSION", "1.49.0")
const ARCHIVE_CACHE_DIR = get(ENV, "AERON_ARCHIVE_CACHE", joinpath(homedir(), ".cache", "aeron"))

function archive_integration_enabled()
    val = lowercase(get(ENV, "AERON_ARCHIVE_INTEGRATION", ""))
    return val in ("1", "true", "yes")
end

function archive_jar_path()
    jar_env = get(ENV, "AERON_ARCHIVE_JAR", "")
    if !isempty(jar_env)
        return jar_env
    end

    jar_path = joinpath(ARCHIVE_CACHE_DIR, "aeron-all-$(ARCHIVE_VERSION).jar")
    if isfile(jar_path)
        return jar_path
    end

    download = lowercase(get(ENV, "AERON_ARCHIVE_DOWNLOAD", ""))
    if !(download in ("1", "true", "yes"))
        return nothing
    end

    mkpath(ARCHIVE_CACHE_DIR)
    url = "https://repo1.maven.org/maven2/io/aeron/aeron-all/$(ARCHIVE_VERSION)/aeron-all-$(ARCHIVE_VERSION).jar"
    Downloads.download(url, jar_path)
    return jar_path
end

function with_archiving_media_driver(f::Function)
    jar_path = archive_jar_path()
    jar_path === nothing && error("Archive integration enabled but Aeron jar is unavailable.")

    root = mktempdir()
    aeron_dir = joinpath(root, "aeron")
    archive_dir = joinpath(root, "archive")
    mkpath(aeron_dir)
    mkpath(archive_dir)

    function free_port()
        server = listen(IPv4("127.0.0.1"), 0)
        port = getsockname(server)[2]
        close(server)
        return port
    end

    control_port = free_port()
    events_port = free_port()
    control_channel = "aeron:udp?endpoint=localhost:$(control_port)"
    response_channel = "aeron:udp?endpoint=localhost:0"
    events_channel = "aeron:udp?endpoint=localhost:$(events_port)"
    control_stream_id = 1001
    response_stream_id = 1002
    events_stream_id = 1003

    log_path = joinpath(root, "archiving-media-driver.log")
    log_io = open(log_path, "w")
    cmd = Cmd([
        "java",
        "--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED",
        "-Daeron.dir=$(aeron_dir)",
        "-Daeron.archive.dir=$(archive_dir)",
        "-Daeron.archive.segment.file.length=65536",
        "-Daeron.archive.control.channel=$(control_channel)",
        "-Daeron.archive.control.stream.id=$(control_stream_id)",
        "-Daeron.archive.control.response.channel=$(response_channel)",
        "-Daeron.archive.control.response.stream.id=$(response_stream_id)",
        "-Daeron.archive.recording.events.channel=$(events_channel)",
        "-Daeron.archive.recording.events.stream.id=$(events_stream_id)",
        "-Daeron.archive.replication.channel=aeron:udp?endpoint=localhost:0",
        "-cp",
        jar_path,
        "io.aeron.archive.ArchivingMediaDriver",
    ])

    proc = run(pipeline(cmd; stdout=log_io, stderr=log_io); wait=false)
    try
        wait_for(; timeout=20.0, sleep_s=0.05) do
            if !Base.process_running(proc)
                error("ArchivingMediaDriver exited early. See log at $(log_path).")
            end
            isfile(joinpath(aeron_dir, "cnc.dat"))
        end
        f((
            aeron_dir=aeron_dir,
            archive_dir=archive_dir,
            control_channel=control_channel,
            response_channel=response_channel,
            events_channel=events_channel,
            control_stream_id=control_stream_id,
            response_stream_id=response_stream_id,
            events_stream_id=events_stream_id,
        ))
    finally
        close(log_io)
        if Base.process_running(proc)
            Base.kill(proc)
        end
        wait(proc)
    end
end
