#!/bin/bash

csvpath="/media/henry/Tools/map/data/"

# get from: https://github.com/openmaptiles/import-osmborder/releases
csvfile="osmborder_lines.csv"

dbname="world"

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

### greate generalized tables
# ref: https://www.cyberciti.biz/tips/bash-shell-parameter-substitution-2.html
function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-""}
    printf "start ${target}...\n"
    docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
        -c "DROP TABLE IF EXISTS ${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE ${target} AS (SELECT osm_id, ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry${columns} FROM ${source} WHERE ${filter})" \
        -c "CREATE INDEX ON ${target} USING gist (geometry)" \
        -c "ANALYZE ${target}"
    printf "${target} ${GREEN}done${NC}\n"
}

# docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
#     -c "CREATE TABLE osmborder (osm_id bigint, admin_level int, dividing_line bool, disputed bool, maritime bool, geometry Geometry(LineString, 3857));" \
#     -c "CREATE INDEX ON osmborder USING gist (geometry);" \

# ### Import OSM-data
# if [ -f ${osmpath}${osmfile} ]; then 
#     ./pgfutter \
#         --schema "public" \
#         --host "localhost" \
#         --port "5432" \
#         --dbname "${dbname}" \
#         --username "postgres" \
#         --table "osmborder" \
#         csv \
#         --fields "osm_id,admin_level,dividing_line,disputed,maritime,geometry" \
#         --delimiter $'\t' \
#         "${csvpath}${csvfile}"
#     OUT=$?
# else
#     printf "${RED}ERROR${NC}: ${osmpath}${osmfile} not found.\n" 
#     exit 1
# fi

OUT=0
if [ $OUT -eq 0 ];then
    # generalize "osmborder" "osmborder_gen14" 5 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    # generalize "osmborder" "osmborder_gen12" 10 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    # generalize "osmborder" "osmborder_gen10" 50 ", admin_level, dividing_line, disputed, maritime" "admin_level <=6" &
    # generalize "osmborder" "osmborder_gen8" 100 ", admin_level, dividing_line, disputed, maritime" "admin_level <=4" &
    # generalize "osmborder" "osmborder_gen6" 1000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=4"&
    # generalize "osmborder" "osmborder_gen4" 10000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=2"&
    generalize "osmborder" "osmborder_gen2" 10000000 ", admin_level, dividing_line, disputed, maritime" "admin_level <=2"&
    wait

    ### show resulting database size
    docker run --rm --net gis img-postgis:0.9 psql -h postgis -U postgres -d ${dbname} \
        -c "SELECT pg_size_pretty(pg_database_size('${dbname}')) as db_size;"
else
   printf "${RED}ERROR${NC}\n"
fi