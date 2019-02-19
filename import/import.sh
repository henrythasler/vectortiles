#!/bin/bash

# Eval command line arguments
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
SERVER=false

while getopts "h?s" opt; do
    case "$opt" in
    h|\?)
        printf " -s for server version"
        exit 0
        ;;
    s)  SERVER=true
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

### Configure names, folders, etc.
pgdocker="postgis11"

if ${SERVER}
then
    printf "using server configuration"
    osmpath="$(pwd)/../data/pbf/"
    dbpath="vectortiles_db"

    osmfile="bayern-latest.osm.pbf"
    dbname="slice"
else
    # localhost
    osmpath="/media/henry/Tools/map/data/"
    dbpath="/media/mapdata/pgdata_mvt"

    osmfile="slice.osm.pbf"
    # osmfile="hessen-latest.osm.pbf"

    dbname="slice"
fi
# server

# auto-generate database-name from input-file (remove '.' and '-' characters)
# dbname=${osmfile%%.*}
# dbname=${dbname%%-*}

mappingfile="$(pwd)/mapping.yaml"

#defines
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

### Start postgis-container 
if ! ${SERVER}
then
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
            -v $(pwd)/postgis-import.conf:/etc/postgresql/postgresql.conf \
            -e PGDATA=/pgdata \
            img-postgis:0.9 -c 'config_file=/etc/postgresql/postgresql.conf'

        ### Wait until startup is complete
        # FIXME: fin some other solution to wait for completion
        sleep 3s
    else echo "${pgdocker} container already running"
    fi
fi

### Setup database
# docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres \
#     -c "DROP DATABASE IF EXISTS ${dbname};" >/dev/null \
#     -c "COMMIT;" 2>&1 >/dev/null \
#     -c "CREATE DATABASE ${dbname} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

# docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
#     -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
#     -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" \
#     -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" \
#     -c "CREATE EXTENSION IF NOT EXISTS hstore;" \
#     -c "ALTER DATABASE ${dbname} SET postgis.backend = sfcgal;"

# ### Import OSM-data
# if [ -f ${osmpath}${osmfile} ]; then 
#     docker run --network gis --rm \
#         -v ${osmpath}${osmfile}:/opt/imposm3/osmdata.osm.pbf:ro \
#         -v ${mappingfile}:/opt/imposm3/mapping.yaml:ro \
#         jawg/imposm3 import \
#             -mapping mapping.yaml \
#             -read osmdata.osm.pbf \
#             -overwritecache -write -optimize -connection 'postgis://postgres@'${pgdocker}'/'${dbname}'?prefix=NONE'
#     OUT=$?
# else
#     printf "${RED}ERROR${NC}: ${osmpath}${osmfile} not found.\n" 
#     exit 1
# fi

### greate generalized tables
# ref: https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html
function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    printf "start import.${target}...\n"
    docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}

function generalize_buffer() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    printf "start import.${target}...\n"
    docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_MakeValid(ST_SimplifyPreserveTopology(ST_Buffer(ST_Buffer(geometry,2*${tolerance}), -2*${tolerance}), ${tolerance})) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}


function generalize_hull() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    local percent=${6:-0.99}
    printf "start import.${target}...\n"
    docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_ConcaveHull(ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})), ${percent}, false) AS geometry${columns} FROM import.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}"
    printf "import.${target} ${GREEN}done${NC}\n"
}


function merge_to_point() {
    local source1=${1}
    local source2=${2}
    local target=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    printf "start import.${target}...\n"
    docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS import.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE import.${target} AS (SELECT osm_id, ST_PointOnSurface(geometry) AS geometry${columns} FROM import.${source1} WHERE ${filter} UNION ALL SELECT osm_id, geometry${columns} FROM import.${source2} WHERE ${filter})" \
        -c "CREATE INDEX ON import.${target} USING gist (geometry)" \
        -c "ANALYZE import.${target}" \
        -c "DROP TABLE IF EXISTS import.${source1}" 2>&1 >/dev/null \
        -c "DROP TABLE IF EXISTS import.${source2}" 2>&1 >/dev/null
    printf "import.${target} ${GREEN}done${NC}\n"
}


 OUT=0
if [ $OUT -eq 0 ];then
    # # landuse
    # generalize "landuse" "landuse_gen14" 5 ", class, subclass" "ST_Area(geometry)>1000" &
    # generalize "landuse" "landuse_gen13" 10 ", class, subclass" "ST_Area(geometry)>2000" &
    # wait

    # generalize_buffer "landuse_gen13" "landuse_gen12" 20 ", class, subclass" "ST_Area(geometry)>5000" &
    # generalize_buffer "landuse_gen13" "landuse_gen11" 50 ", class, subclass" "ST_Area(geometry)>50000" &
    # generalize_buffer "landuse_gen13" "landuse_gen10" 100 ", class, subclass" "ST_Area(geometry)>200000" &

    # generalize_buffer "landuse_gen13" "landuse_gen9" 150 ", class, subclass" "ST_Area(geometry)>2000000" &
    # generalize_buffer "landuse_gen13" "landuse_gen8" 200 ", class, subclass" "ST_Area(geometry)>4000000" &
    # wait

    # # landcover
    # generalize "landcover" "landcover_gen14" 5 ", class, subclass, surface" "ST_Area(geometry)>1000" &
    # generalize "landcover" "landcover_gen13" 10 ", class, subclass, surface" "ST_Area(geometry)>2000" &
    # wait

    # generalize_buffer "landcover_gen13" "landcover_gen12" 20 ", class, subclass, surface" "ST_Area(geometry)>5000" &
    # generalize_buffer "landcover_gen13" "landcover_gen11" 50 ", class, subclass, surface" "ST_Area(geometry)>50000" &
    # generalize_buffer "landcover_gen13" "landcover_gen10" 100 ", class, subclass, surface" "ST_Area(geometry)>200000" &
    # generalize_buffer "landcover_gen13" "landcover_gen9" 150 ", class, subclass, surface" "ST_Area(geometry)>2000000" &
    # generalize_buffer "landcover_gen13" "landcover_gen8" 200 ", class, subclass, surface" "ST_Area(geometry)>5000000" &
    # wait

    # # waterarea
    # generalize "waterarea" "waterarea_gen14" 5 ", class, subclass" "ST_Area(geometry)>1000" &
    # generalize "waterarea" "waterarea_gen13" 10 ", class, subclass" "ST_Area(geometry)>2000" &
    # wait

    # generalize "waterarea_gen13" "waterarea_gen12" 20 ", class, subclass" "ST_Area(geometry)>5000" &
    # generalize "waterarea_gen13" "waterarea_gen11" 50 ", class, subclass" "ST_Area(geometry)>50000" &
    # generalize "waterarea_gen13" "waterarea_gen10" 100 ", class, subclass" "ST_Area(geometry)>200000" &
    # generalize "waterarea_gen13" "waterarea_gen9" 200 ", class, subclass" "ST_Area(geometry)>2000000" &
    # generalize "waterarea_gen13" "waterarea_gen8" 250 ", class, subclass" "ST_Area(geometry)>5000000" &
    # wait

    # # waterway
    # generalize "waterway" "waterway_gen12" 20 ", class, subclass, tunnel, layer" "ST_Length(geometry)>50" &
    # generalize "waterway" "waterway_gen10" 50 ", class, subclass, tunnel, layer" "ST_Length(geometry)>100" &
    # generalize "waterway" "waterway_gen8" 100 ", class, subclass, tunnel, layer" "ST_Length(geometry)>200" &
    # wait

    # # transportation
    # generalize "transportation" "transportation_gen12" 20 ", class, subclass" "ST_Length(geometry)>50" &
    # generalize "transportation" "transportation_gen10" 50 ", class, subclass" "ST_Length(geometry)>100" &
    # generalize "transportation" "transportation_gen8" 100 ", class, subclass" "ST_Length(geometry)>200" &
    # wait

    # # roads
    # generalize "roads" "roads_gen15" 3 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "(service <=1) OR (ST_Length(geometry) > 50)" &
    # generalize "roads" "roads_gen14" 5 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=15 OR (subclass IN ('path', 'track', 'footway', 'bridleway', 'service', 'cycleway') AND ST_Length(geometry) > 100)" &
    # generalize "roads" "roads_gen13" 10 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=15 OR (subclass IN ('path', 'track', 'footway', 'bridleway', 'service', 'cycleway') AND ST_Length(geometry) > 200)" &
    # generalize "roads" "roads_gen12" 20 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=15 OR (subclass='path' AND bicycle >= 3) OR (subclass IN ('track', 'service', 'cycleway') AND ST_Length(geometry) > 500)" &
    # generalize "roads" "roads_gen10" 50 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=10" &
    # generalize "roads" "roads_gen9" 100 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=4" &
    # generalize "roads" "roads_gen8" 200 ", class, subclass, oneway, tracktype, bridge, tunnel, service, layer, rank, bicycle, scale" "rank<=3" &
    # wait

    # # manmade_lines
    # generalize "manmade_lines" "manmade_lines_gen13" 10 ", class, subclass" "subclass IN('taxiway', 'runway')" &
    # wait

    # housenumbers
    merge_to_point "buildings_temp" "housenumbers_temp" "housenumbers" ", number, name_de, name_en, name" "(number <> '') IS NOT FALSE"
    wait


    printf "generalize ${GREEN}done${NC}\n"

    ### show resulting database size
    docker run --rm --net gis img-postgis:0.9 psql -h ${pgdocker} -U postgres -d ${dbname} \
        -c "SELECT pg_size_pretty(pg_database_size('${dbname}')) as db_size;"
else
   printf "${RED}ERROR${NC}\n"
fi
