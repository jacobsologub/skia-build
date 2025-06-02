#!/bin/bash

# build-skia-arch.sh - Shared Skia build script for specific architecture
# Usage: ./build-skia-arch.sh <arch>
# Where <arch> is either "arm64" or "x64"

# Function to detect ICU installation
detect_icu() {
    echo "Detecting ICU installation..."
    
    # Check Homebrew ICU first
    if command -v brew >/dev/null 2>&1; then
        icu_prefix=$(brew --prefix icu4c 2>/dev/null)
        if [ -n "$icu_prefix" ] && [ -d "$icu_prefix" ]; then
            # Verify ICU headers exist
            if [ -d "$icu_prefix/include/unicode" ]; then
                export ICU_ROOT="$icu_prefix"
                icu_version=$(brew list --versions icu4c 2>/dev/null | head -1 | awk '{print $2}')
                echo "✓ Found ICU via Homebrew at: $ICU_ROOT"
                if [ -n "$icu_version" ]; then
                    echo "✓ ICU version: $icu_version"
                fi
                return 0
            fi
        fi
    fi
    
    # Check standard macOS locations
    for path in /opt/homebrew /usr/local; do
        if [ -d "$path/include/unicode" ] && [ -d "$path/lib" ]; then
            # Basic verification that ICU libraries exist
            if ls "$path/lib/"*icu* >/dev/null 2>&1; then
                export ICU_ROOT="$path"
                echo "✓ Found ICU at: $ICU_ROOT"
                return 0
            fi
        fi
    done
    
    echo "⚠ No compatible system ICU found"
    echo "ℹ To install ICU via Homebrew: brew install icu4c"
    return 1
}

# ICU Configuration Function
configure_icu() {
    # Always try to use system ICU to avoid conflicts with V8's bundled ICU
    if detect_icu; then
        echo "✓ Configuring build to use system ICU (avoids V8 conflicts)"
        echo 'skia_use_icu = true' >> $args_file
        echo 'skia_use_system_icu = true' >> $args_file
        
        # Add ICU-specific compilation flags if we have a custom path
        if [ -n "$ICU_ROOT" ] && [ "$ICU_ROOT" != "/usr/local" ]; then
            echo "extra_cflags = [\"-I$ICU_ROOT/include\"]" >> $args_file
            echo "extra_ldflags = [\"-L$ICU_ROOT/lib\"]" >> $args_file
        fi
    else
        echo "⚠ No system ICU found - this may cause conflicts with V8's bundled ICU"
        echo "ℹ Strongly recommended: brew install icu4c"
        echo "ℹ Disabling ICU in Skia to avoid V8 conflicts"
        echo 'skia_use_icu = false' >> $args_file
    fi
}

if [ $# -eq 0 ]; then
    echo "Error: Architecture required"
    echo "Usage: $0 <arch>"
    echo "  <arch>  Target architecture (arm64 or x64)"
    exit 1
fi

arch=$1

# Validate architecture
if [ "$arch" != "arm64" ] && [ "$arch" != "x64" ]; then
    echo "Error: Invalid architecture '$arch'"
    echo "Supported architectures: arm64, x64"
    exit 1
fi

script_dir=$(pwd);

./get_depot_tools.sh;
export PATH=$(pwd)/depot_tools:$PATH;

./fetch.sh;

cd src/skia;
python3 tools/git-sync-deps;
python3 bin/fetch-ninja;

release_name=release-macos-$arch;

rm -rf out/$release_name;
mkdir -p out/$release_name;

args_file=out/$release_name/args.gn;
echo 'is_official_build = true' >> $args_file;
echo "target_cpu = \"$arch\"" >> $args_file;
echo 'skia_use_system_expat = false' >> $args_file;
echo 'skia_use_system_libjpeg_turbo = false' >> $args_file;
echo 'skia_use_system_libpng = false' >> $args_file;
echo 'skia_use_system_libwebp = false' >> $args_file;
echo 'skia_use_system_zlib = false' >> $args_file;
configure_icu;
echo 'skia_use_system_harfbuzz = false' >> $args_file;
echo 'skia_use_metal = true' >> $args_file;
echo 'extra_cflags_cc=["-fexceptions", "-frtti"]' >> $args_file;

bin/gn gen out/$release_name

ninja -C out/$release_name;
