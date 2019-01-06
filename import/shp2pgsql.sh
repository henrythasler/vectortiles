#!/bin/bash
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "DROP TABLE IF EXISTS $SHP_TABLE;" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 

### auto-detect CRS. The tail-part is a bit hacky...
#FIXME: find another solution to determine shapefile CRS
crs=$(ogrinfo -ro -al -so $SHP_FILE | grep "AUTHORITY" | tail -n1 | grep -Eo "[0-9]+")

shp2pgsql -s ${crs} -I -g geometry $SHP_FILE $SHP_TABLE | psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB > /dev/null