# Aeron.jl

Julia wrappers around the [Aeron Client](https://github.com/real-logic/aeron) C library for reliable UDP unicast, multicast, and shared-memory messaging.

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

**Note:** A media driver must be running before executing any samples. To start a media driver in the Julia environment:

```julia
using Aeron
launch_media_driver()
```
The media driver can be configured passing environment variable strings to [launch_media_driver](src/Aeron.jl#L255). 
For more information on configuring the media driver, see the [Aeron wiki](https://github.com/real-logic/aeron/wiki/Configuration-Options).

For usage examples, please refer to the [samples directory](samples) in the repository.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## Contact

For more information, please contact the project maintainers.
