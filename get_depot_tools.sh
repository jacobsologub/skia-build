#!/bin/bash

script_dir=$(pwd);

if [ ! -d depot_tools ]; then
    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git;
else
    cd depot_tools;
    git pull origin main;
    cd $script_dir;
fi
