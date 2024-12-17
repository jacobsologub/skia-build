#!/bin/bash

script_dir=$(pwd);

./build-macos-x64.sh;
./build-macos-arm64.sh;

cd $script_dir;

if [ -d "src/skia/out/release-macos-universal" ]; then
	rm -rf src/skia/out/release-macos-universal;	
fi

mkdir src/skia/out/release-macos-universal;

find src/skia/out/release-macos-x64 -name '*.a' | xargs -n 1 basename;

for filename in $(find src/skia/out/release-macos-x64 -type f -name "*.a" | xargs -n 1 basename); do
    lipo -create src/skia/out/release-macos-x64/$filename \
			     src/skia/out/release-macos-arm64/$filename \
	 	 -output src/skia/out/release-macos-universal/$filename;
done
