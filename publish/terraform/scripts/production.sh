#!/bin/bash

echo "starting up..."
imposm import -mapping mapping.yaml -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE' -deployproduction
echo "all done"
