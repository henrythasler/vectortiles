#!/bin/bash

echo "starting up..."
aws s3 cp s3://gis-data-0001/${IMPORT_FILE} osmdata.osm.pbf
aws s3 cp s3://gis-data-0001/import/mapping.yaml mapping.yaml
imposm import -mapping mapping.yaml -read osmdata.osm.pbf -overwritecache -write -optimize -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE'
echo "all done"
