#!/bin/bash

script_dir=$(pwd);

# Parse command line arguments
build_universal=false
for arg in "$@"; do
    case $arg in
        --universal)
            build_universal=true
            shift
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [--universal]"
            echo "  --universal  Build both x64 and arm64 architectures and create universal binaries"
            exit 1
            ;;
    esac
done

# Detect current architecture
current_arch=$(uname -m)
if [ "$current_arch" = "x86_64" ]; then
    current_arch="x64"
elif [ "$current_arch" = "arm64" ]; then
    current_arch="arm64"
else
    echo "Unsupported architecture: $current_arch"
    exit 1
fi

if [ "$build_universal" = true ]; then
    echo "Building universal binaries (x64 + arm64)..."
    
    # Build both architectures
    ./build-macos-arch.sh x64;
    ./build-macos-arch.sh arm64;
    
    cd $script_dir;
    
    # Create universal binary directory
    if [ -d "src/skia/out/release-macos" ]; then
        rm -rf src/skia/out/release-macos;
    fi
    
    mkdir -p src/skia/out/release-macos;
    
    # Combine all .a files using lipo
    echo "Creating universal binaries..."
    for filename in $(find src/skia/out/release-macos-x64 -type f -name "*.a" | xargs -n 1 basename); do
        echo "Processing $filename..."
        lipo -create src/skia/out/release-macos-x64/$filename \
                     src/skia/out/release-macos-arm64/$filename \
             -output src/skia/out/release-macos/$filename;
    done
    
    # Clean up individual architecture outputs
    rm -rf src/skia/out/release-macos-x64;
    rm -rf src/skia/out/release-macos-arm64;
    
    echo "Universal binaries created in: src/skia/out/release-macos/"
else
    echo "Building for current architecture ($current_arch)..."
    
    # Build only for current architecture
    ./build-macos-arch.sh $current_arch;
    
    # Copy the single architecture build to the generic output location
    if [ -d "src/skia/out/release-macos" ]; then
        rm -rf src/skia/out/release-macos;
    fi
    mkdir -p src/skia/out/release-macos;
    
    # Copy all files from architecture-specific build
    cp -r src/skia/out/release-macos-$current_arch/* src/skia/out/release-macos/;
    
    # Clean up architecture-specific output
    rm -rf src/skia/out/release-macos-$current_arch;
    
    echo "Build complete for $current_arch architecture"
    echo "Output: src/skia/out/release-macos/"
fi
