#!/bin/bash
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

### Setup database
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} \
    -c "DROP DATABASE IF EXISTS ${SHAPE_DATABASE_NAME};" >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null \
    -c "CREATE DATABASE ${SHAPE_DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"
    
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" 2>&1 >/dev/null \
    -c "ALTER DATABASE ${SHAPE_DATABASE_NAME} SET postgis.backend = sfcgal;" 2>&1 >/dev/null


### Import all shapefiles in given folder
for folder in $(find /shp/ -mindepth 1 -maxdepth 1 -type d) 
do
    for file in ${folder}/*.shp
    do
        table="$(basename -- ${file})"
        table=${table%.*}
        printf "%s\n" ${table}
        
        psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} -c "DROP TABLE IF EXISTS ${table};" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 

        ### auto-detect CRS. The tail-part is a bit hacky...
        #FIXME: find another solution to determine shapefile CRS
        crs=$(ogrinfo -ro -al -so ${file} | grep "AUTHORITY" | tail -n1 | grep -Eo "[0-9]+")

        shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
    done
    printf ${GREEN}"OK"${NC}"\n"
done

### generate generalized tables
# docker run \
#     -it \
#     --rm \
#     --net gis \
#     -v ${shapefolder}:${shapefolder}:ro \
#     -v $(pwd)/scripts/generalize.sh:/generalize.sh:ro \
#     -e POSTGRES_USER="postgres" \
#     -e POSTGRES_HOST="postgis" \
#     -e POSTGRES_DB=${dbname} \
#     img-postgis:0.9 /generalize.sh
