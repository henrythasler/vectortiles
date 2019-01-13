#!/bin/bash

### Configure names, folders, etc.

# change the input file here
osmfile="slice.osm.pbf"
#osmfile="oberbayern-latest.osm.pbf"
# osmfile="germany-south.osm.pbf"
dbname="slice"

osmpath="/media/henry/Tools/map/data/"
dbpath="/media/mapdata/pgdata_mvt"

# auto-generate database-name from input-file (remove '.' and '-' characters)
# dbname=${osmfile%%.*}
# dbname=${dbname%%-*}

mappingfile="$(pwd)/mapping.yaml"

#defines
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

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
docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres \
    -c "DROP DATABASE IF EXISTS ${dbname};" >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null \
    -c "CREATE DATABASE ${dbname} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
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
        -overwritecache -write -connection 'postgis://postgres@postgis/'${dbname}'?prefix=NONE'


### greate generalized tables
# ref: https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html
function generalize() {
    local source=${1}
    local target=${2}
    local arealimit=${3:-0}
    local tolerance=${4:-0}
    docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry, area, class, subclass, surface FROM import.${source} WHERE ST_Area(geometry)>${arealimit})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function generalize_hull() {
    local source=${1}
    local target=${2}
    local arealimit=${3:-0}
    local tolerance=${4:-0}
    local percent=${5:-0.99}
    docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_ConcaveHull(ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})), ${percent}) AS geometry, area, class, subclass, surface FROM import.${source} WHERE ST_Area(geometry)>${arealimit})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

generalize "landuse" "landuse_gen14" 1000 5 &
generalize "landuse" "landuse_gen13" 2000 10 &
wait

generalize "landuse_gen13" "landuse_gen12" 5000 20 & 
generalize "landuse_gen13" "landuse_gen11" 50000 50 &
generalize "landuse_gen13" "landuse_gen10" 200000 100 &
wait

generalize_hull "landuse_gen10" "landuse_gen9" 2000000 200 0.95 &
generalize_hull "landuse_gen10" "landuse_gen8" 5000000 500 0.98 &
wait

printf "generalize ${GREEN}done${NC}\n"

### show resulting database size
docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
    -c "SELECT pg_size_pretty(pg_database_size('${dbname}')) as db_size;"
