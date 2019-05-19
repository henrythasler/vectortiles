#!/bin/bash

#defines
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

### Setup database
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} \
    -c "DROP DATABASE IF EXISTS ${DATABASE_NAME};" >/dev/null \
    -c "COMMIT;" 2>&1 >/dev/null \
    -c "CREATE DATABASE ${DATABASE_NAME} WITH ENCODING='UTF8' CONNECTION LIMIT=-1;"

psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${DATABASE_NAME} \
    -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_topology;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;" 2>&1 >/dev/null \
    -c "CREATE EXTENSION IF NOT EXISTS hstore;" 2>&1 >/dev/null \
    -c "ALTER DATABASE ${DATABASE_NAME} SET postgis.backend = geos;" 2>&1 >/dev/null

printf "${GREEN}All done${NC}\n"
