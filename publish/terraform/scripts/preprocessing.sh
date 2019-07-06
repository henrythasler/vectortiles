#!/bin/bash

### Setup database
echo "starting up..."

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w \
    -c "DROP DATABASE IF EXISTS ${DATABASE_NAME};" \
    -c "COMMIT;" \
    -c "CREATE DATABASE ${DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w -d ${DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" \
    -c "ALTER DATABASE ${DATABASE_NAME} SET postgis.backend = geos;"

echo "setup done"
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -w -d ${DATABASE_NAME} \
    -c "SELECT PostGIS_full_version();" \
    -c "SHOW rds.extensions;"

