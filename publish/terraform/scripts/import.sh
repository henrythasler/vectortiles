#!/bin/bash

echo "starting up..."
aws s3 cp s3://${GIS_DATA_BUCKET}/data/pbf/${IMPORT_FILE} osmdata.osm.pbf
aws s3 cp s3://${GIS_DATA_BUCKET}/imposm/mapping.yaml mapping.yaml
imposm import -mapping mapping.yaml -read osmdata.osm.pbf -overwritecache -write -optimize -connection 'postgis://'${POSTGIS_USER}':'${PGPASSWORD}'@'${POSTGIS_HOSTNAME}'/'${DATABASE_NAME}'?prefix=NONE'
echo "all done"
