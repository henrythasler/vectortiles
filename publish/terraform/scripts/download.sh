#!/bin/bash
echo "starting up..."
wget -qO- ${DOWNLOAD_URL} | aws s3 cp - s3://${GIS_DATA_BUCKET}/data/pbf/${OBJECT_NAME}
echo "all done"