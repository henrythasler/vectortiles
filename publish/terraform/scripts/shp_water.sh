#!/bin/bash

# exit when any command fails
set -e

mkdir -p shp
aws s3 cp s3://${GIS_DATA_BUCKET}/${SHAPEFOLDER} ./shp --recursive --quiet
printf "Done fetching shapefiles\n"

SOURCE="shp/${SHAPEFILE}"

printf "gdal_rasterize (${RESOLUTION}x${RESOLUTION}): "
gdal_rasterize -init 255 -burn 0 -ot Byte -ts ${RESOLUTION} ${RESOLUTION} -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES ${SOURCE}.shp rasterized.tif

# prepare vrt
printf "gdalbuildvrt: "
gdalbuildvrt rasterized.vrt rasterized.tif

# add blur https://gis.stackexchange.com/questions/20196/how-to-convert-geotiff-to-grayscale-and-add-gaussian-blur
sed -i "s/SimpleSource/KernelFilteredSource/" rasterized.vrt
sed -i "s/<KernelFilteredSource>/<KernelFilteredSource>\nKERNEL/" rasterized.vrt
sed -i "s/KERNEL/<Kernel normalized=\"1\">\n<Size>5<\/Size>\n<Coefs>\nCOEFS\n<\/Coefs>\n<\/Kernel>/" rasterized.vrt
sed -i "s/COEFS/0.0036630037 0.0146520147 0.0256410256 0.0146520147 0.0036630037\n \
0.0146520147 0.0586080586 0.0952380952 0.0586080586 0.0146520147\n \
0.0256410256 0.0952380952 0.1501831502 0.0952380952 0.0256410256\n \
0.0146520147 0.0586080586 0.0952380952 0.0586080586 0.0146520147\n \
0.0036630037 0.0146520147 0.0256410256 0.0146520147 0.0036630037/" rasterized.vrt

# convert to shapefile
printf "gdal_contour: "
gdal_contour -fl 128 -p rasterized.vrt raw.shp

# use just water polygon
ogr2ogr -fid 0 filtered.shp raw.shp

# count grid features
count=$(ogrinfo -ro -al -sql "SELECT COUNT(id) FROM ${GRID}" /grids/${GRID}.shp | grep "(Integer)" | grep -Eo "[0-9]+")
printf "slicing with grid (${count} features): "

# slice resulting shapefile using grid
ogr2ogr "${OUTPUT}.shp" -clipsrc "/grids/${GRID}.shp" -clipsrcwhere id=1 filtered.shp
for (( i = 2; i <= $count; i++ )) 
do
    if [ $(( $i % 10 )) -eq 0 ]; then
        printf "."
    fi
    ogr2ogr -append "${OUTPUT}.shp" -clipsrc "/grids/${GRID}.shp" -clipsrcwhere id=${i} filtered.shp
done
printf "done\n"

printf "starting import into \"${SHAPE_DATABASE_NAME}\", table \"${OUTPUT}\".\n"
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} -c "DROP TABLE IF EXISTS ${OUTPUT};" 2>&1 >/dev/null -c "COMMIT;" 2>&1 >/dev/null 
shp2pgsql -s 3857 -I -g geometry ${OUTPUT}.shp ${OUTPUT} | psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} > /dev/null

### show resulting database size
psql -h ${POSTGIS_HOSTNAME} -U ${POSTGIS_USER} -d ${SHAPE_DATABASE_NAME} \
    -c "SELECT pg_size_pretty(pg_database_size('${SHAPE_DATABASE_NAME}')) as db_size;"