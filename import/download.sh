#!/bin/bash

### Configure names, folders, etc.
shapefolder="/media/henry/Tools/map/data/shp/"
shapefiles=(
    # http://data.openstreetmapdata.com/simplified-water-polygons-complete-3857.zip
    # http://data.openstreetmapdata.com/water-polygons-split-3857.zip
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes.zip
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes_europe.zip
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_rivers_lake_centerlines.zip
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_rivers_europe.zip    
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geographic_lines.zip
    # https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip
    # http://data.openstreetmapdata.com/water-polygons-generalized-3857.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_bathymetry_all.zip
)

#defines
NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'


mkdir -p ${shapefolder}

for index in ${!shapefiles[*]}
do
    filename="$(basename -- ${shapefiles[$index]})"
    printf "[%2d/%d] - %s" $((${index}+1)) ${#shapefiles[*]} ${filename}
    wget ${shapefiles[$index]} -O ${shapefolder}${filename}

    if [ -f "${shapefolder}${filename}" ]
    then
        mkdir -p ${shapefolder}${filename%.*}
        unzip -q ${shapefolder}${filename} -d ${shapefolder}${filename%.*}

        for folder in $(find ${shapefolder}${filename%.*} -mindepth 1 -maxdepth 1 -type d) 
        do
            # printf "%s\n" ${folder}
            mv ${folder}/* ${shapefolder}${filename%.*}
            rm -r ${folder}
        done
        rm ${shapefolder}${filename}
        printf ${GREEN}" ok"
    else
        printf ${RED}" Download error"
    fi
    printf ${NC}"\n"
done

