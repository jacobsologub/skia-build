#!/bin/bash

script_dir=$(pwd);

./get_depot_tools.sh;
export PATH=$(pwd)/depot_tools:$PATH;

./fetch.sh;

cd src/skia;
python3 tools/git-sync-deps;
python3 bin/fetch-ninja;

release_name=Static;

rm -rf out/$release_name;
mkdir -p out/$release_name;


args_file=out/$release_name/args.gn;
echo "is_official_build = true" >> $args_file;
echo "target_cpu = \"arm64\"" >> $args_file;
echo "skia_use_system_expat = false" >> $args_file;
echo "skia_use_system_libjpeg_turbo = false" >> $args_file;
echo "skia_use_system_libpng = false" >> $args_file;
echo "skia_use_system_libwebp = false" >> $args_file;
echo "skia_use_system_zlib = false" >> $args_file;
echo "skia_use_system_icu = false" >> $args_file;
echo "skia_use_system_harfbuzz = false" >> $args_file;

bin/gn gen out/$release_name

ninja -C out/$release_name;
