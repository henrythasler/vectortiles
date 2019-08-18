#!/bin/bash

### Configure names, folders, etc.
shapefolder="data/shp/"
shapefiles=(
    https://osmdata.openstreetmap.de/download/simplified-water-polygons-split-3857.zip
    https://osmdata.openstreetmap.de/download/water-polygons-split-3857.zip
    # http://data.openstreetmapdata.com/water-polygons-generalized-3857.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_lakes_europe.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_rivers_lake_centerlines.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_rivers_europe.zip    
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geographic_lines.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_bathymetry_all.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geography_marine_polys.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geography_regions_elevation_points.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geography_regions_points.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/physical/ne_10m_geography_regions_polys.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_populated_places_simple.zip
    https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_urban_areas.zip
)

mkdir -p ${shapefolder}

for index in ${!shapefiles[*]}
do
    filename="$(basename -- ${shapefiles[$index]})"
    printf "[%2d/%d] - %s" $((${index}+1)) ${#shapefiles[*]} ${filename}
    wget ${shapefiles[$index]} -qO ${shapefolder}${filename}

    if [ -f "${shapefolder}${filename}" ]
    then
        # '%.*' removes the '.' and all (*) characters from the right of the whole string. 
        # Here: remove file extension from zip-file to create a folder from the filename
        mkdir -p ${shapefolder}${filename%.*}
        unzip -q ${shapefolder}${filename} -d ${shapefolder}${filename%.*}

        for folder in $(find ${shapefolder}${filename%.*} -mindepth 1 -maxdepth 1 -type d) 
        do
            # printf "%s\n" ${folder}
            mv ${folder}/* ${shapefolder}${filename%.*}
            rm -r ${folder}
        done
        rm ${shapefolder}${filename}
        aws s3 cp ${shapefolder}${filename%.*}/ s3://${GIS_DATA_BUCKET}/data/shp/${filename%.*} --recursive --no-progress
        printf " ok"
    else
        printf " Download error"
    fi
done

