#!/bin/bash

mkdir -p data

# 1:50m Shaded Relief
if [ ! -f data/SR_50M/SR_50M.tif ]; then
    echo "downloading 1:50m Shaded Relief"
    wget https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/raster/SR_50M.zip -O data/SR_50M.zip
    unzip data/SR_50M.zip SR_50M/* -d data
    rm data/SR_50M.zip
fi
