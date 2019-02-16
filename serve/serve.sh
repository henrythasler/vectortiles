#!/bin/bash

### Configure names, folders, etc.
dbpath="/media/mapdata/pgdata_mvt"
config="$(pwd)/config/cyclemap.toml"
cache="$(pwd)/.cache"

### Start postgis-container 
if [ ! "$(docker ps -q -f name=${pgdocker})" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=${pgdocker})" ]; then
        echo "removing old ${pgdocker} container"
        docker rm ${pgdocker}
    fi
    # run container as current user
    echo "starting ${pgdocker} container"
    docker run -d \
        --name ${pgdocker} \
        --network gis \
        -p 5432:5432 \
        --user "$(id -u):$(id -g)" \
        -v ${dbpath}:/pgdata \
        -v $(pwd)/postgis.conf:/etc/postgresql/postgresql.conf \
        -e PGDATA=/pgdata \
        img-postgis:0.9 -c 'config_file=/etc/postgresql/postgresql.conf'

    ### Wait until startup is complete
    # FIXME: fin some other solution to wait for completion
    sleep 3s
else echo "${pgdocker} container already running"
fi

mkdir -p ${cache}
rm -rf ${cache}/global
rm -rf ${cache}/local

### start tileserver
docker run \
    --rm \
    --network gis \
    -p 8080:8080 \
    --user "$(id -u):$(id -g)" \
    -v ${config}:/data/config.toml:ro \
    -v ${cache}:/cache \
    -e TEGOLA_SQL_DEBUG=LAYER_SQL \
    tegola:master serve \
        --config /data/config.toml \
