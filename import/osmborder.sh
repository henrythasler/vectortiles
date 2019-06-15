#!/bin/bash

# get from: https://github.com/openmaptiles/import-osmborder/releases
osmborder_filename="osmborder_lines.csv"
osmborder_gzip="osmborder_lines.csv.gz"
osmborder_location="https://github.com/openmaptiles/import-osmborder/releases/download/v0.4/"

schema="public"

pgfutter_filename="pgfutter_linux_386"
pgfutter_location="https://github.com/lukasmartinelli/pgfutter/releases/download/v1.2/"

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

### greate generalized tables
function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    printf "start ${schema}.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS ${schema}.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE ${schema}.${target} AS (SELECT osm_id, ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry${columns} FROM ${schema}.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON ${schema}.${target} USING gist (geometry)" \
        -c "ANALYZE ${schema}.${target}"
    printf "${schema}.${target} ${GREEN}done${NC}\n"
}

# download import tool if not already available
if [ ! -f /data/${pgfutter_filename} ]; then 
    wget ${pgfutter_location}${pgfutter_filename} -O /data/${pgfutter_filename}
    chmod +x /data/${pgfutter_filename}
    if [ ! $? -eq 0 ];then
        printf "${RED}ERROR${NC}: ${pgfutter_location}${pgfutter_filename} not found.\n" 
        exit 1    
    fi
fi

# download data if not available
if [ ! -f /data/${osmborder_filename} ]; then 
    if [ ! -f /data/${osmborder_gzip} ]; then 
        wget ${osmborder_location}${osmborder_gzip} -O /data/${osmborder_gzip}
        if [ ! $? -eq 0 ];then
            printf "${RED}ERROR${NC}: ${osmborder_location}${osmborder_gzip} not found.\n" 
            exit 1    
        fi
    fi
    gzip -dv /data/${osmborder_gzip}
fi

### Import OSM-data
OUT=0
if [ -f /data/${osmborder_filename} ]; then 
    # prepare table
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS ${schema}.osmborder" 2>&1 >/dev/null \
        -c "CREATE TABLE ${schema}.osmborder (osm_id bigint, admin_level int, dividing_line bool, disputed bool, maritime bool, geometry Geometry(LineString, 3857));" \
        -c "CREATE INDEX ON ${schema}.osmborder USING gist (geometry);"

    # import data
    ./data/${pgfutter_filename} \
        --schema "${schema}" \
        --host "${POSTGIS_HOSTNAME}" \
        --port "5432" \
        --dbname "${SHAPE_DATABASE_NAME}" \
        --username "${POSTGIS_USER}" \
        --table "osmborder" \
        csv \
        --fields "osm_id,admin_level,dividing_line,disputed,maritime,geometry" \
        --delimiter $'\t' \
        "/data/${osmborder_filename}"
    OUT=$?
else
    printf "${RED}ERROR${NC}: /data/${osmborder_filename} not found.\n" 
    exit 1
fi



if [ $OUT -eq 0 ];then
    generalize "osmborder" "osmborder_gen14" 5 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    generalize "osmborder" "osmborder_gen12" 10 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    generalize "osmborder" "osmborder_gen10" 50 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    generalize "osmborder" "osmborder_gen8" 100 ", admin_level, dividing_line, disputed, maritime" "admin_level <=4" &
    generalize "osmborder" "osmborder_gen6" 1000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=4"&
    generalize "osmborder" "osmborder_gen4" 10000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=2"&
    generalize "osmborder" "osmborder_gen2" 10000000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=2"&
    wait

    ### show resulting database size
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"
else
   printf "${RED}ERROR${NC}\n"
fi