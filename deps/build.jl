using BinaryProvider

const JLCXX_DIR = get(ENV, "JLCXX_DIR", "")
const verbose = "--verbose" in ARGS
const prefix = Prefix(JLCXX_DIR == "" ? get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")) : JLCXX_DIR)

products = Product[
    LibraryProduct(prefix, "libcxxwrap_julia", :libcxxwrap_julia)
]

supported = true

# Download binaries from hosted location
bin_prefix = "https://github.com/JuliaInterop/libcxxwrap-julia/releases/download/v0.4.0"

# Listing of files generated by BinaryBuilder:
if VERSION == v"0.7"
    download_info = Dict(
        Windows(:i686) => ("$bin_prefix/libcxxwrap-julia-0.7.v0.4.0.i686-w64-mingw32.tar.gz", "d747600938a9d4aaaa6808781d4bafbb55c81d59cf9196c3d6ecf8223e305d2d"),
        MacOS(:x86_64) => ("$bin_prefix/libcxxwrap-julia-0.7.v0.4.0.x86_64-apple-darwin14.tar.gz", "69101f73560153e003b052c121ab9631e7d74b70e0d8a9108aaaafa1fb992265"),
        Linux(:x86_64, :glibc) => ("$bin_prefix/libcxxwrap-julia-0.7.v0.4.0.x86_64-linux-gnu.tar.gz", "7dafd9db3dd898151ce54bf52ff5b6d7dc417a70fc88ac2594d73c53f284c461"),
        Windows(:x86_64) => ("$bin_prefix/libcxxwrap-julia-0.7.v0.4.0.x86_64-w64-mingw32.tar.gz", "e634a847567de9b3335281dad9d452f1dd6a1b4dc885740ea79463bde16de9e1"),
    )
elseif VERSION == v"1.0"
    download_info = Dict(
        Windows(:i686) => ("$bin_prefix/libcxxwrap-julia-1.0.v0.4.0.i686-w64-mingw32.tar.gz", "6c55c7ca0bc70c23a72b22eccbf8b1ff7edf222251ccbc1542ce07f7956f4b33"),
        MacOS(:x86_64) => ("$bin_prefix/libcxxwrap-julia-1.0.v0.4.0.x86_64-apple-darwin14.tar.gz", "39adc979fe8a5daaa11beabe55d93696bae9d143a68a68f4c115543640666bd9"),
        Linux(:x86_64, :glibc) => ("$bin_prefix/libcxxwrap-julia-1.0.v0.4.0.x86_64-linux-gnu.tar.gz", "78d2c534d9b120559e1dda76aec7bdd8d5059fbe8acc4af656f76b5e204a9f95"),
        Windows(:x86_64) => ("$bin_prefix/libcxxwrap-julia-1.0.v0.4.0.x86_64-w64-mingw32.tar.gz", "4973c3a406be02d0f76b6a9bcdd1680693683831ebab271d70be7e7ed3128b40"),
    )
else
    download_info = Dict()
    supported = false
end

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
if JLCXX_DIR == ""
    if haskey(download_info, platform_key())
        if !supported
            error("Julia version $VERSION is not supported for binary download. Please build libcxxwrap-julia from source and set the JLCXX_DIR environment variable to the build dir or installation prefix.")
        end
        url, tarball_hash = download_info[platform_key()]
        if unsatisfied || !isinstalled(url, tarball_hash; prefix=prefix)
            # Download and install binaries
            install(url, tarball_hash; prefix=prefix, force=true, verbose=verbose)
        end
    elseif unsatisfied
        # If we don't have a BinaryProvider-compatible .tar.gz to download, complain.
        # Alternatively, you could attempt to install from a separate provider,
        # build from source or something even more ambitious here.
        error("Your platform $(triplet(platform_key())) is not supported by this package!")
    end
else
    if unsatisfied
        error("The libcxxwrap-julia library was not found in the provided JLCXX_DIR directory $JLCXX_DIR")
    end
end

write_deps_file(joinpath(@__DIR__, "deps.jl"), products)
