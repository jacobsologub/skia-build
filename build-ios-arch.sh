#!/bin/bash

# build-ios-arch.sh - Shared iOS Skia build script for specific architecture
# Usage: ./build-ios-arch.sh <target> <arch>
# Where <target> is "device" or "simulator"
# Where <arch> is "arm64" or "x64"

if [ $# -lt 2 ]; then
    echo "Error: Target and architecture required"
    echo "Usage: $0 <target> <arch>"
    echo "  <target>  Build target (device or simulator)"
    echo "  <arch>    Target architecture (arm64 or x64)"
    exit 1
fi

target=$1
arch=$2

# Validate target
if [ "$target" != "device" ] && [ "$target" != "simulator" ]; then
    echo "Error: Invalid target '$target'"
    echo "Supported targets: device, simulator"
    exit 1
fi

# Validate architecture
if [ "$arch" != "arm64" ] && [ "$arch" != "x64" ]; then
    echo "Error: Invalid architecture '$arch'"
    echo "Supported architectures: arm64, x64"
    exit 1
fi

# Validate target/arch combination
if [ "$target" = "device" ] && [ "$arch" = "x64" ]; then
    echo "Error: iOS devices do not support x64 architecture"
    echo "Use arm64 for iOS devices"
    exit 1
fi

script_dir=$(pwd);

./get_depot_tools.sh;
export PATH=$(pwd)/depot_tools:$PATH;

./fetch.sh;

cd src/skia;
python3 tools/git-sync-deps;
python3 bin/fetch-ninja;

# Determine output directory name
if [ "$target" = "device" ]; then
    release_name=release-ios-device-$arch;
    target_os="ios"
else
    release_name=release-ios-simulator-$arch;
    target_os="ios"
fi

rm -rf out/$release_name;
mkdir -p out/$release_name;

args_file=out/$release_name/args.gn;

# Common iOS build settings
echo 'is_official_build = true' >> $args_file;
echo "target_os = \"$target_os\"" >> $args_file;
echo "target_cpu = \"$arch\"" >> $args_file;

# iOS-specific settings
if [ "$target" = "simulator" ]; then
    echo 'ios_use_simulator = true' >> $args_file;
else
    echo 'ios_use_simulator = false' >> $args_file;
fi

# Set minimum iOS version
echo 'ios_min_target = "12.0"' >> $args_file;

# Disable system libraries (use bundled versions for consistency)
echo 'skia_use_system_expat = false' >> $args_file;
echo 'skia_use_system_libjpeg_turbo = false' >> $args_file;
echo 'skia_use_system_libpng = false' >> $args_file;
echo 'skia_use_system_libwebp = false' >> $args_file;
echo 'skia_use_system_zlib = false' >> $args_file;
echo 'skia_use_system_icu = false' >> $args_file;
echo 'skia_use_system_harfbuzz = false' >> $args_file;
echo 'skia_use_system_freetype2 = false' >> $args_file;

# Enable HarfBuzz for text shaping
echo 'skia_use_harfbuzz = true' >> $args_file;

# iOS doesn't need ICU configuration like macOS
echo 'skia_use_icu = true' >> $args_file;

# Enable Metal for iOS
echo 'skia_use_metal = true' >> $args_file;

# Enable C++ features
echo 'extra_cflags_cc=["-fexceptions", "-frtti"]' >> $args_file;

# iOS-specific optimizations
echo 'skia_enable_gpu = true' >> $args_file;
echo 'skia_use_gl = false' >> $args_file;  # Metal only on iOS

# Disable features not needed for iOS
echo 'skia_use_x11 = false' >> $args_file;
echo 'skia_use_fontconfig = false' >> $args_file;
echo 'skia_use_freetype = true' >> $args_file;
echo 'skia_enable_skottie = true' >> $args_file;
echo 'skia_enable_pdf = true' >> $args_file;
echo 'skia_enable_skshaper = true' >> $args_file;

# Generate build files
bin/gn gen out/$release_name

# Build
ninja -C out/$release_name;