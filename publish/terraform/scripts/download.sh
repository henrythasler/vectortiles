#!/bin/bash
wget -qO- http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf | aws s3 cp - s3://gis-data-0001/oberfranken-latest.osm.pbf
