#!/bin/bash

script_dir=$(pwd);

# Parse command line arguments
build_type="device"
build_universal=false
build_xcframework=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --device        Build for iOS device (arm64) [default]"
    echo "  --simulator     Build for iOS simulator (current host architecture)"
    echo "  --universal     Build universal simulator binary (x64 + arm64)"
    echo "  --xcframework   Build XCFramework with device and universal simulator"
    echo ""
    echo "Examples:"
    echo "  $0                     # Build for device (arm64)"
    echo "  $0 --simulator         # Build for simulator (current arch)"
    echo "  $0 --simulator --universal  # Build universal simulator binary"
    echo "  $0 --xcframework       # Build XCFramework (device + universal sim)"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --device)
            build_type="device"
            shift
            ;;
        --simulator)
            build_type="simulator"
            shift
            ;;
        --universal)
            build_universal=true
            shift
            ;;
        --xcframework)
            build_xcframework=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Detect current host architecture for simulator builds
current_arch=$(uname -m)
if [ "$current_arch" = "x86_64" ]; then
    current_arch="x64"
elif [ "$current_arch" = "arm64" ]; then
    current_arch="arm64"
else
    echo "Unsupported architecture: $current_arch"
    exit 1
fi

if [ "$build_type" = "device" ]; then
    if [ "$build_universal" = true ]; then
        echo "Error: Universal build is only supported for simulators"
        echo "iOS devices only support arm64 architecture"
        exit 1
    fi
    
    echo "Building for iOS device (arm64)..."
    ./build-ios-arch.sh device arm64;
    
    cd $script_dir;
    
    # Move output to generic location
    if [ -d "src/skia/out/release-ios-device" ]; then
        rm -rf src/skia/out/release-ios-device;
    fi
    mv src/skia/out/release-ios-device-arm64 src/skia/out/release-ios-device;
    
    echo "iOS device build complete (arm64)"
    echo "Output: src/skia/out/release-ios-device/"
    
elif [ "$build_type" = "simulator" ]; then
    if [ "$build_universal" = true ]; then
        echo "Building universal iOS simulator binaries (x64 + arm64)..."
        
        # Build both architectures
        ./build-ios-arch.sh simulator x64;
        ./build-ios-arch.sh simulator arm64;
        
        cd $script_dir;
        
        # Create universal binary directory
        if [ -d "src/skia/out/release-ios-simulator" ]; then
            rm -rf src/skia/out/release-ios-simulator;
        fi
        
        mkdir -p src/skia/out/release-ios-simulator;
        
        # Combine all .a files using lipo
        echo "Creating universal simulator binaries..."
        for filename in $(find src/skia/out/release-ios-simulator-x64 -type f -name "*.a" | xargs -n 1 basename); do
            echo "Processing $filename..."
            lipo -create src/skia/out/release-ios-simulator-x64/$filename \
                         src/skia/out/release-ios-simulator-arm64/$filename \
                 -output src/skia/out/release-ios-simulator/$filename;
        done
        
        # Clean up individual architecture outputs
        rm -rf src/skia/out/release-ios-simulator-x64;
        rm -rf src/skia/out/release-ios-simulator-arm64;
        
        echo "Universal iOS simulator binaries created"
        echo "Output: src/skia/out/release-ios-simulator/"
    else
        echo "Building iOS simulator for current architecture ($current_arch)..."
        
        # Build only for current architecture
        ./build-ios-arch.sh simulator $current_arch;
        
        cd $script_dir;
        
        # Copy to generic output location
        if [ -d "src/skia/out/release-ios-simulator" ]; then
            rm -rf src/skia/out/release-ios-simulator;
        fi
        mkdir -p src/skia/out/release-ios-simulator;
        
        # Copy all files from architecture-specific build
        cp -r src/skia/out/release-ios-simulator-$current_arch/* src/skia/out/release-ios-simulator/;
        
        # Clean up architecture-specific output
        rm -rf src/skia/out/release-ios-simulator-$current_arch;
        
        echo "iOS simulator build complete for $current_arch architecture"
        echo "Output: src/skia/out/release-ios-simulator/"
    fi
elif [ "$build_xcframework" = true ]; then
    echo "Building XCFramework (device + universal simulator)..."
    
    # Build device libraries
    echo "Building iOS device libraries..."
    ./build-ios-arch.sh device arm64;
    
    # Build universal simulator libraries
    echo "Building universal iOS simulator libraries..."
    ./build-ios-arch.sh simulator x64;
    ./build-ios-arch.sh simulator arm64;
    
    cd $script_dir;
    
    # Create universal simulator directory
    if [ -d "src/skia/out/release-ios-simulator-universal" ]; then
        rm -rf src/skia/out/release-ios-simulator-universal;
    fi
    
    mkdir -p src/skia/out/release-ios-simulator-universal;
    
    # Combine simulator architectures
    echo "Creating universal simulator binaries..."
    for filename in $(find src/skia/out/release-ios-simulator-x64 -type f -name "*.a" | xargs -n 1 basename); do
        lipo -create src/skia/out/release-ios-simulator-x64/$filename \
                     src/skia/out/release-ios-simulator-arm64/$filename \
             -output src/skia/out/release-ios-simulator-universal/$filename;
    done
    
    # Create XCFramework for each library
    echo "Creating XCFrameworks..."
    
    if [ -d "src/skia/out/xcframeworks" ]; then
        rm -rf src/skia/out/xcframeworks;
    fi
    
    mkdir -p src/skia/out/xcframeworks;
    
    # Note: XCFramework requires framework bundles, not static libraries directly
    # For static libraries, we need to create a fat library that developers can use
    # Alternatively, we can combine all .a files into a single libskia.a for each platform
    
    # Combine all static libraries into single libskia.a for each platform
    echo "Combining static libraries..."
    
    # Device
    mkdir -p src/skia/out/release-ios-device-combined;
    libtool -static -o src/skia/out/release-ios-device-combined/libskia.a \
            src/skia/out/release-ios-device-arm64/*.a;
    
    # Simulator
    mkdir -p src/skia/out/release-ios-simulator-combined;
    libtool -static -o src/skia/out/release-ios-simulator-combined/libskia.a \
            src/skia/out/release-ios-simulator-universal/*.a;
    
    # Create XCFramework
    xcodebuild -create-xcframework \
        -library src/skia/out/release-ios-device-combined/libskia.a \
        -library src/skia/out/release-ios-simulator-combined/libskia.a \
        -output src/skia/out/xcframeworks/skia.xcframework;
    
    # Clean up intermediate directories
    rm -rf src/skia/out/release-ios-device-arm64;
    rm -rf src/skia/out/release-ios-simulator-x64;
    rm -rf src/skia/out/release-ios-simulator-arm64;
    rm -rf src/skia/out/release-ios-simulator-universal;
    rm -rf src/skia/out/release-ios-device-combined;
    rm -rf src/skia/out/release-ios-simulator-combined;
    
    echo "XCFramework created successfully!"
    echo "Output: src/skia/out/xcframeworks/skia.xcframework"
    echo ""
    echo "This XCFramework contains:"
    echo "  - iOS device (arm64)"
    echo "  - iOS simulator (x64 + arm64 universal)"
    echo ""
    echo "To use in Xcode, drag skia.xcframework into your project."
fi