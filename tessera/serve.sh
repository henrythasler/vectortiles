#!/bin/bash

docker run \
    --rm \
    -ti \
    --network gis \
    -p 8080:8080 \
    -v $(pwd):/node-mapnik \
    afrith/node-mapnik:latest bash