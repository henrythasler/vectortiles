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

# globals
pgdocker="postgis11"
config="$(pwd)/config/cyclemap.toml"
cache="$(pwd)/.cache"

mkdir -p ${cache}

if ${SERVER}
then
    printf "using server configuration\n"

    dbpath="vectortiles_db" # volume container

    if [ "$(sudo docker ps -q -f name=${pgdocker})" ]; then
        ### start tileserver
        sudo docker run \
            -d \
            --name tegola \
            --network gis \
            -p 8081:8080 \
            --user "$(id -u):$(id -g)" \
            -v ${config}:/data/config.toml:ro \
            -v ${cache}:/cache \
            tegola:master serve \
                --config /data/config.toml
    else echo "${pgdocker} container not running"
    fi
else
    # localhost
    ### Configure names, folders, etc.
    dbpath="/media/mapdata/pgdata_mvt"

    rm -rf ${cache}/local 

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

    ### start tileserver
    docker run \
        --rm \
        --name tegola \
        --network gis \
        -p 8080:8080 \
        --user "$(id -u):$(id -g)" \
        -v ${config}:/data/config.toml:ro \
        -v ${cache}:/cache \
        tegola:henry serve \
            --config /data/config.toml
fi

#        -e TEGOLA_SQL_DEBUG=LAYER_SQL:EXECUTE_SQL \
