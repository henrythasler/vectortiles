#!/bin/bash
tables=(
    "public.simplified_water_polygons:"

)

psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB \
    -c "DROP TABLE IF EXISTS" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 
