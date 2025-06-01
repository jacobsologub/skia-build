#!/bin/bash

# build-skia-arch.sh - Shared Skia build script for specific architecture
# Usage: ./build-skia-arch.sh <arch>
# Where <arch> is either "arm64" or "x64"

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
echo 'skia_use_system_icu = false' >> $args_file;
echo 'skia_use_system_harfbuzz = false' >> $args_file;
echo 'skia_use_metal = true' >> $args_file;
echo 'extra_cflags_cc=["-fexceptions", "-frtti"]' >> $args_file;

bin/gn gen out/$release_name

ninja -C out/$release_name;
