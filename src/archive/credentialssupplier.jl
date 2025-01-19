Base.@kwdef struct CredentialsSupplier
    encoded_credentials::Function = default_encoded_credentials_supplier
    on_chalenge::Function = default_encoded_challenge_supplier
    clientd::Any = nothing
end

function Base.convert(::Type{aeron_archive_encoded_credentials_t}, ec::String)
    aeron_archive_encoded_credentials_t(Base.pointer(ec), length(ec))
end

function Base.cconvert(::Type{Ptr{aeron_archive_encoded_credentials_t}}, ec::String)
    Ref(convert(aeron_archive_encoded_credentials_t, ec))
end

function credentials_encoded_credentials_supplier_wrapper(supplier)
    credentials = Ref(Base.convert(aeron_archive_encoded_credentials_t, supplier.encoded_credentials(supplier.clientd)))
    return Base.unsafe_convert(Ptr{aeron_archive_encoded_credentials_t}, credentials)
end

# function credentials_encoded_credentials_supplier_wrapper(supplier)
#     Base.unsafe_convert(Ptr{aeron_archive_encoded_credentials_t},
#         Base.cconvert(aeron_archive_encoded_credentials_t, supplier.encoded_credentials(supplier.clientd)))
# end

function credentials_encoded_credentials_supplier_cfunction(::T) where {T}
    @cfunction(credentials_encoded_credentials_supplier_wrapper, Ptr{aeron_archive_encoded_credentials_t}, (Ref{T},))
end

function credentials_encoded_challenge_supplier_wrapper(encoded_challenge, supplier)
    credentials = Ref(convert(aeron_archive_encoded_credentials_t, supplier.on_chalenge(encoded_challenge, supplier.clientd)))
    return Base.unsafe_convert(Ptr{aeron_archive_encoded_credentials_t}, credentials)
end

# function credentials_encoded_challenge_supplier_wrapper(encoded_challenge, supplier)
#     Base.unsafe_convert(Ptr{aeron_archive_encoded_credentials_t},
#         Base.cconvert(aeron_archive_encoded_credentials_t, supplier.on_chalenge(encoded_challenge, supplier.clientd)))
# end

function credentials_encoded_challenge_supplier_cfunction(::T) where {T}
    @cfunction(credentials_encoded_challenge_supplier_wrapper, Ptr{aeron_archive_encoded_credentials_t}, (Ptr{aeron_archive_encoded_credentials_t}, Ref{T}))
end

function default_encoded_credentials_supplier(arg)
    return ""
end

function default_encoded_challenge_supplier(encoded_challenge, arg)
    return ""
end
