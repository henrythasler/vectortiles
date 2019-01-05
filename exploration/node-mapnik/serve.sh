#!/bin/bash
dbpath="/media/mapdata/pgdata_mvt"

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

docker run \
    --rm \
    -ti \
    --network gis \
    -p 8000:8000 \
    -v $(pwd):/node-mapnik \
    afrith/node-mapnik:latest node node-mapnik/server.js