#!/bin/bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
SERVER=false

while getopts "h?s" opt; do
    case "$opt" in
    h|\?)
        printf " -s for server version"
        exit 0
        ;;
    s)  SERVER=true
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

### Configure names, folders, etc.
pgdocker="postgis11"

mkdir -p ${cache}
#rm -rf ${cache}/global
rm -rf ${cache}/local

if ${SERVER}
then
    printf "using server configuration\n"
    dbpath="vectortiles_db"
    config="$(pwd)/config/cyclemap.toml"
    cache="$(pwd)/.cache"
    ### start tileserver
    docker run \
        --rm \
        --network gis \
        --user "1000:1000" \
        -v ${config}:/data/config.toml:ro \
        -v ${cache}:/cache \
        -e TEGOLA_SQL_DEBUG=LAYER_SQL \
        tegola:master cache seed \
            --config /data/config.toml \
            --max-zoom 4 \
            --map global \
            --overwrite
else
    # localhost
    dbpath="/media/mapdata/pgdata_mvt"
    config="$(pwd)/config/cyclemap.toml"
    cache="$(pwd)/.cache"

    ### Start postgis-container 
    if [ ! "$(docker ps -q -f name=${pgdocker})" ]; then
        if [ "$(docker ps -aq -f status=exited -f name=${pgdocker})" ]; then
            echo "removing old ${pgdocker} container"
            docker rm ${pgdocker}
        fi
        # run container as current user
        echo "starting ${pgdocker} container"
        docker run -d \
            --name ${pgdocker} \
            --network gis \
            -p 5432:5432 \
            --user "$(id -u):$(id -g)" \
            -v ${dbpath}:/pgdata \
            -v $(pwd)/postgis.conf:/etc/postgresql/postgresql.conf \
            -e PGDATA=/pgdata \
            img-postgis:0.9 -c 'config_file=/etc/postgresql/postgresql.conf'

        ### Wait until startup is complete
        # FIXME: fin some other solution to wait for completion
        sleep 3s
    else echo "${pgdocker} container already running"
    fi

    # printf "Building global cache...\n"
    # docker run \
    #     --rm \
    #     --network gis \
    #     --user "$(id -u):$(id -g)" \
    #     -v ${config}:/data/config.toml:ro \
    #     -v ${cache}:/cache \
    #     -e TEGOLA_SQL_DEBUG=LAYER_SQL \
    #     tegola:master cache seed \
    #         --config /data/config.toml \
    #         --min-zoom 0 \
    #         --max-zoom 3 \
    #         --map global \
    #         --overwrite

    printf "Building local cache...\n"
    docker run \
        --rm \
        --network gis \
        --user "$(id -u):$(id -g)" \
        -v ${config}:/data/config.toml:ro \
        -v $(pwd)/expired_tiles.txt:/data/expired_tiles.txt \
        -v ${cache}:/cache \
        -e TEGOLA_SQL_DEBUG=LAYER_SQL \
        tegola:master cache seed tile-list /data/expired_tiles.txt \
            --config /data/config.toml \
            --min-zoom 9 \
            --max-zoom 14 \
            --map local \
            --overwrite
fi

