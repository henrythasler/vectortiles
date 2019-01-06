#!/bin/bash

### Note
# This script assumes the current user is allowed to use docker.

### Database configuration
dbname="world"
dbpath="/media/mapdata/pgdata_mvt"

### Shapefiles
shapefolder="/media/henry/Tools/map/data/shp/"

### Start postgis-container 
if [ ! "$(docker ps -q -f name=postgis)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=postgis)" ]; then
        echo "removing old postgis container"
        docker rm postgis
    fi
    # run container as current user
    echo "starting postgis container"
    docker run -d \
        --name postgis \
        --network gis \
        -p 5432:5432 \
        --user "$(id -u):$(id -g)" \
        -v ${dbpath}:/pgdata \
        -v $(pwd)/postgis-import.conf:/etc/postgresql/postgresql.conf \
        -e PGDATA=/pgdata \
        img-postgis:0.9 -c 'config_file=/etc/postgresql/postgresql.conf'

    ### Wait until startup is complete
    # FIXME: fin some other solution to wait for completion
    sleep 3s
else echo "postgis container already running"
fi

### Setup database
# docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres \
#     -c "DROP DATABASE IF EXISTS ${dbname};" \
#     -c "COMMIT;" \
#     -c "CREATE DATABASE ${dbname} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" \
    -c "ALTER DATABASE ${dbname} SET postgis.backend = sfcgal;"

### Import all shapefiles in given folder
for folder in $(find ${shapefolder} -mindepth 1 -maxdepth 1 -type d) 
do
    for file in ${folder}/*.shp
    do
        table="$(basename -- ${file})"
        table=${table%.*}
        printf "%s\n" ${table}

        docker run \
            -it \
            --rm \
            --net gis \
            -v ${shapefolder}:${shapefolder}:ro \
            -v $(pwd)/shp2pgsql.sh:/shp2pgsql.sh:ro \
            -e POSTGRES_USER="postgres" \
            -e POSTGRES_HOST="postgis" \
            -e POSTGRES_DB=${dbname} \
            -e SHP_FILE=${file} \
            -e SHP_TABLE=${table} \
            img-postgis:0.9 /shp2pgsql.sh
        # exit 1
    done
    printf ${NC}"\n"
done

