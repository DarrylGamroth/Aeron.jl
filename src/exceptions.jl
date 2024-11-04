"""
    abstract type AeronException <: Exception

An abstract type for Aeron exceptions.

This serves as a base type for different Aeron-specific exceptions.
"""
abstract type AeronException <: Exception end

macro define_exception(name)
    quote
        struct $name{T<:AbstractString} <: AeronException
            msg::T
        end
        Base.showerror(io::IO, e::$name) = println(io, e.msg)
    end
end

@define_exception IllegalStateException
@define_exception IOException
@define_exception DriverTimeoutException
@define_exception ClientTimeoutException
@define_exception ConductorServiceTimeoutException
@define_exception TimedOutException
@define_exception GeneralAeronException

"""
    map_to_exception_and_throw(code::Int32, message::AbstractString) -> Nothing

Maps an error code to an appropriate exception type and throws it with the given message.

# Arguments

- `code::Int32`: The error code.
- `message::AbstractString`: The error message.

# Returns

- `Nothing`: This function does not return a value.
"""
function map_to_exception_and_throw(code, message)
    if code == Libc.EINVAL
        throw(ArgumentError(message))
    elseif code == Libc.EPERM || code == AERON_CLIENT_ERROR_BUFFER_FULL
        throw(IllegalStateException(message))
    elseif code == Libc.EIO || code == Libc.ENOENT
        throw(IOException(message))
    elseif code == AERON_CLIENT_ERROR_DRIVER_TIMEOUT
        throw(DriverTimeoutException(message))
    elseif code == AERON_CLIENT_ERROR_CLIENT_TIMEOUT
        throw(ClientTimeoutException(message))
    elseif code == AERON_CLIENT_ERROR_CONDUCTOR_SERVICE_TIMEOUT
        throw(ConductorServiceTimeoutException(message))
    elseif code == Libc.ETIMEDOUT
        throw(TimedOutException(message))
    elseif code == 0
        return
    else
        throw(AeronException(message))
    end
    return
end

"""
    throwerror() -> Nothing

Throws an appropriate exception based on the current Aeron error code and message.

# Returns

- `Nothing`: This function does not return a value.
"""
function throwerror()
    map_to_exception_and_throw(aeron_errcode(), unsafe_string(aeron_errmsg()))
end
