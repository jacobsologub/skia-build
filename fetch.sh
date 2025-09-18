#!/bin/bash

script_dir=$(pwd);

gclient;

if [ ! -d src ]; then
    mkdir src;
    cd src;
    fetch skia;
fi

cd $script_dir;

# Read Skia version from version.txt
if [ -f version.txt ]; then
    skia_version=$(cat version.txt);
    echo "Checking out Skia version: $skia_version";
    cd src/skia;
    git fetch origin;
    git checkout $skia_version;
    cd $script_dir;
else
    echo "Warning: version.txt not found, using latest Skia version";
fi
