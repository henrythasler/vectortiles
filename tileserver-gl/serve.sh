#!/bin/bash

docker run \
    --rm \
    -ti \
    -v $(pwd):/data \
    -p 8080:80 \
    klokantech/tileserver-gl \
        --config /data/config.json \
        --verbose