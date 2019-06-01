#!/bin/bash
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'

# apk upgrade --update
# apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing proj4-dev gdal-dev

### Setup database
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} \
    -c "CREATE DATABASE ${SHAPE_DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;" 2>&1 >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" 2>&1 >/dev/null \
    -c "ALTER DATABASE ${SHAPE_DATABASE_NAME} SET postgis.backend = sfcgal;" 2>&1 >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null

### Import all shapefiles in given folder
for folder in $(find /shp/ -mindepth 1 -maxdepth 1 -type d) 
do
    for file in ${folder}/*.shp
    do
        table="$(basename -- ${file})"
        table=${table%.*}
        printf "${BOLD}%s${NC}\n" ${table}
        
        psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} -c "DROP TABLE IF EXISTS ${table};" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 

        ### auto-detect CRS. The tail-part is a bit hacky...
        #FIXME: find another solution to determine shapefile CRS
        crs=$(ogrinfo -ro -al -so ${file} | grep "AUTHORITY" | tail -n1 | grep -Eo "[0-9]+")

        # shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
        # exit
        if [ ${crs} != "3857" ]
        then
            printf "${YELLOW}Reprojecting${NC} from EPSG:${crs} to EPSG:3857\n"
            base=`basename $file .shp`

            # ogr2ogr --config PG_USE_COPY YES -t_srs EPSG:3857 -f PostgreSQL PG:"host=${POSTGIS_HOSTNAME} user=${POSTGIS_USER} dbname=${SHAPE_DATABASE_NAME}" ${file} 
            ogr2ogr -clipsrc -180.0 -85.06 180.0 85.06 -lco ENCODING=UTF-8 -t_srs EPSG:3857 /{$base}-3857.shp ${file} > /dev/null
            if [ $? -eq 0 ]
            then 
                shp2pgsql -s 3857 -I -g geometry /{$base}-3857.shp ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
            else
                printf "${RED}Failed${NC} Importing with source CRS\n"
                shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
            fi
        else
            shp2pgsql -s ${crs} -I -g geometry ${file} ${table} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null
        fi
        printf "${GREEN}OK${NC}\n\n"
    done
done

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"