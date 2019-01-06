#!/bin/bash

### Configure names, folders, etc.

# change the input file here
# osmfile="slice.osm.pbf"
osmfile="oberbayern-latest.osm.pbf"
# osmfile="germany-south.osm.pbf"
dbname="slice"

osmpath="/media/henry/Tools/map/data/"
dbpath="/media/mapdata/pgdata_mvt"

# auto-generate database-name from input-file (remove '.' and '-' characters)
# dbname=${osmfile%%.*}
# dbname=${dbname%%-*}

mappingfile="$(pwd)/mapping.yaml"

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
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres \
    -c "DROP DATABASE IF EXISTS ${dbname};" >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null \
    -c "CREATE DATABASE ${dbname} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" \
    -c "ALTER DATABASE ${dbname} SET postgis.backend = sfcgal;"

### Import OSM-data
docker run --network gis --rm \
    -v ${osmpath}${osmfile}:/opt/imposm3/osmdata.osm.pbf:ro \
    -v ${mappingfile}:/opt/imposm3/mapping.yaml:ro \
    jawg/imposm3 import \
        -mapping mapping.yaml \
        -read osmdata.osm.pbf \
        -overwritecache -write -connection 'postgis://postgres@postgis/'${dbname}

docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
    -c "SELECT pg_size_pretty(pg_database_size('${dbname}')) as db_size;" \
