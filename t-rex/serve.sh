#!/bin/bash

### Start postgis-container
if [ ! "$(docker ps -q -f name=postgis)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=postgis)" ]; then
        echo "removing old postgis container"
        docker rm postgis
    fi
    # run your container
    echo "starting postgis container"
    docker run -d \
    --name postgis \
    --network gis \
    -p 5432:5432 \
    --user "$(id -u):$(id -g)" \
    -v /etc/passwd:/etc/passwd:ro \
    -v ${dbpath}:/pgdata \
    -v $(pwd)/postgis-import.conf:/etc/postgresql/postgresql.conf \
    -e PGDATA=/pgdata \
    img-postgis:0.9 -c 'config_file=/etc/postgresql/postgresql.conf'
else echo "postgis container already running"
fi

### Wait until startup is complete
# FIXME: fin some other solution to wait for completion
sleep 3s

mkdir -p .cache

docker run \
    --rm \
    --network gis \
    -p 6767:6767 \
    --user "$(id -u):$(id -g)" \
    -v $(pwd):/data:ro \
    -v $(pwd)/.cache:/cache \
    sourcepole/t-rex serve \
        --config /data/config.toml \
