
   docker run --rm -ti --link postgis:postgis -p 6767:6767 sourcepole/t-rex serve --dbconn postgresql://postgres@postgis/vector --bind=0.0.0.0 --cache /tmp/mvtcache


## generate sample config file 

    docker run --rm --link postgis:postgis -p 6767:6767 sourcepole/t-rex genconfig --dbconn postgresql://postgres@postgis/mering | tee config.toml

## run with config file

    docker run --rm --link postgis:postgis -p 6767:6767 -v $PWD:/data:ro sourcepole/t-rex serve --config /data/config.toml


docker run --rm -p 6767:6767 -v /media/henry/Tools/map/data:/data:ro sourcepole/t-rex serve --datasource /data/slice.osm.pbf --bind=0.0.0.0


docker run --rm -p 6767:6767 -v /media/henry/Tools/map/data:/map/data:ro -v $PWD:/cfg:ro sourcepole/t-rex generate --config /cfg/pbf.toml




# docker commands

## serve with autoconfiguration

docker run --rm -ti --net gis -p 6767:6767 sourcepole/t-rex serve --dbconn postgresql://postgres@postgis/vector --bind=0.0.0.0

## serve with config-file

docker run --rm --network gis -p 6767:6767 -v $(pwd):/data:ro sourcepole/t-rex serve --config /data/imposm.toml