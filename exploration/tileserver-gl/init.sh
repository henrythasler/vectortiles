#!/bin/bash
mkdir -p data
wget https://github.com/klokantech/vector-tiles-sample/releases/download/v1.0/countries-raster.mbtiles -O data/countries-raster.mbtiles
wget https://github.com/klokantech/vector-tiles-sample/releases/download/v1.0/countries.mbtiles -O data/countries.mbtiles