#!/bin/bash

#defines
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

function generalize() {
    local source=${1}
    local target=${2}
    local tolerance=${3}
    local columns=${4:-""}
    local filter=${5:-"TRUE"}
    printf "start public.${target}...\n"
    psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
        -c "DROP TABLE IF EXISTS public.${target}" 2>&1 >/dev/null \
        -c "CREATE TABLE public.${target} AS (SELECT gid, ST_MakeValid(ST_SimplifyPreserveTopology(geometry, ${tolerance})) AS geometry${columns} FROM public.${source} WHERE ${filter})" \
        -c "CREATE INDEX ON public.${target} USING gist (geometry)" \
        -c "ANALYZE public.${target}"
    printf "public.${target} ${GREEN}done${NC}\n"
}

### merge bathymetry data
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "DROP TABLE IF EXISTS public.bathymetry" 2>&1 >/dev/null \
    -c "CREATE TABLE public.bathymetry (gid serial primary key, depth int4, geometry geometry(MULTIPOLYGON, 3857))" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_k_200;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_j_1000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_i_2000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_h_3000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_g_4000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_f_5000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_e_6000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_d_7000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_c_8000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_b_9000;" \
    -c "INSERT INTO public.bathymetry (depth, geometry) SELECT depth, geometry FROM ne_10m_bathymetry_a_10000;" \
    -c "CREATE INDEX ON public.bathymetry USING gist (geometry)" \
    -c "ANALYZE public.bathymetry"

generalize "bathymetry" "bathymetry_gen4" 5000 ", depth" &
generalize "bathymetry" "bathymetry_gen3" 10000 ", depth" &
wait

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"

printf "${GREEN}Shape postprocessing done${NC}\n"
