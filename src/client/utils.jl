"""
    sizehint_optimized!(vector, n)

Apply `sizehint!` with version-aware optimization.
On Julia 1.11+, uses `shrink=false` to prevent capacity reduction.
This is particularly important for high-performance code where we want to
preserve pre-allocated capacity to avoid future allocations.

# Arguments
- `vector`: The vector to apply sizehint to
- `n`: The hint for capacity

# Returns
- The vector (for chaining)
"""
function sizehint_optimized!(vector, n)
    @static if VERSION >= v"1.11.0"
        sizehint!(vector, n; shrink=false)
    else
        sizehint!(vector, n)
    end
    return vector
end
