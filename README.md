# Aeron.jl

[![CI](https://github.com/DarrylGamroth/Aeron.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/DarrylGamroth/Aeron.jl/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/DarrylGamroth/Aeron.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/DarrylGamroth/Aeron.jl)

Julia wrappers around the [Aeron Client](https://github.com/aeron-io/aeron) C library for reliable UDP unicast, multicast, and shared-memory messaging.

## Features

- Low-latency messaging
- High-throughput communication
- Zero allocations in publication and subscription

## Installation

To install Aeron.jl, use the Julia package manager:

```julia
using Pkg
Pkg.add("Aeron")
```

## Usage

**Note:** A media driver must be running before executing any samples.

To start an embedded media driver:
```julia
using Aeron
media_driver = MediaDriver.launch_embedded()
...
close(media_driver)
```

The embedded media driver creates a unique Aeron directory. To use it pass the directory to the client context.
```julia
dirname = MediaDriver.aeron_dir(media_driver)
context = Aeron.Context()
Aeron.aeron_dir!(context, dirname)
```

To start an external media driver process in the Julia environment:

```julia
using Aeron
launch_media_driver()
```
The media driver can be configured passing environment variable strings to [launch_media_driver](src/Aeron.jl#L20). 
For more information on configuring the media driver, see the [Aeron wiki](https://github.com/aeron-io/aeron/wiki/Configuration-Options).

For usage examples, please refer to the [samples directory](samples) in the repository.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## Contact

For more information, please contact the project maintainers.
