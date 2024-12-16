#!/bin/bash

script_dir=$(pwd);

gclient;

if [ ! -d src ]; then
    mkdir src;
	cd src;
	fetch skia;
fi

cd $script_dir;
