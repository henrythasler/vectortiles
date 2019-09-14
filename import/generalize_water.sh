#!/bin/bash

SOURCE="/media/henry/Tools/map/data/shp/water-polygons-split-3857/water_polygons"
OUTPUT="water"
GRID="grid_coarse"
RESOLUTION=1024

# raster 
#gdal_rasterize -init 255 -burn 0 -ot Byte -ts 2048 2048 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES /media/henry/Tools/map/data/shp/simplified-water-polygons-split-3857/simplified_water_polygons.shp data.tif
gdal_rasterize -init 255 -burn 0 -ot Byte -ts ${RESOLUTION} ${RESOLUTION} -co COMPRESS=DEFLATE -co ZLEVEL=9 -co TILED=YES ${SOURCE}.shp rasterized.tif

# prepare vrt
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
docker run --rm \
        -v $(pwd):/src \
        --user $(id -u):$(id -g) \
        --entrypoint=bash \
        postgis-client:latest -c 'gdal_contour -fl 128 -p /src/rasterized.vrt /src/raw.shp'

# use just water polygon
ogr2ogr -fid 0 filtered.shp raw.shp

# count grid features
count=$(ogrinfo -al -sql "SELECT COUNT(id) FROM ${GRID}" ${GRID}.shp | grep "(Integer)" | grep -Eo "[0-9]+")

# slice resulting shapefile using grid
ogr2ogr ${OUTPUT}.shp -clipsrc ${GRID}.shp -clipsrcwhere id=1  filtered.shp
for (( i = 2; i <= $count; i++ )) 
do
    if [ $(( $i % 10 )) -eq 0 ]; then
        printf "."
    fi
    ogr2ogr -append ${OUTPUT}.shp -clipsrc ${GRID}.shp -clipsrcwhere id=${i} filtered.shp
done
