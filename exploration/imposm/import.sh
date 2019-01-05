#!/bin/bash

### Configure names, folders, etc.
dbname="vector"
dbpath="/media/mapdata/pgdata_mvt"

#osmdata="/media/henry/Tools/map/data/oberbayern-latest.osm.pbf"
osmdata="/media/henry/Tools/map/data/slice.osm.pbf"

mappingfile="$(pwd)/mapping.yaml"

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

### Setup database
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -c "DROP DATABASE IF EXISTS $dbname;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -c "COMMIT;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -c "CREATE DATABASE $dbname WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d $dbname -c "CREATE EXTENSION IF NOT EXISTS postgis;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d $dbname -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d $dbname -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d $dbname -c "CREATE EXTENSION IF NOT EXISTS hstore;"
docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -c "ALTER DATABASE $dbname SET postgis.backend = sfcgal;"


### Add BBox function
IFS='' read -r -d '' BBox <<"EOF"
CREATE OR REPLACE FUNCTION BBox(x integer, y integer, zoom integer)
    RETURNS geometry AS 
$BODY$
DECLARE
    max numeric := 6378137 * pi();
    res numeric := max * 2 / 2^zoom;
    bbox geometry;
BEGIN
    return ST_MakeEnvelope(
        -max + (x * res),
        max - (y * res),
        -max + (x * res) + res,
        max - (y * res) - res,
        3857);
END;
$BODY$
LANGUAGE plpgsql IMMUTABLE;
EOF

docker run -it --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d $dbname -c "$BBox"

### Import OSM-data
docker run --network gis --rm \
    -v ${osmdata}:/opt/imposm3/osmdata.osm.pbf:ro \
    -v ${mappingfile}:/opt/imposm3/mapping.yaml:ro \
    jawg/imposm3 import \
        -mapping mapping.yaml \
        -read osmdata.osm.pbf \
        -overwritecache -write -connection 'postgis://postgres@postgis/'${dbname}
