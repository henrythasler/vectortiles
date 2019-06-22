# vectortiles
Toolchain to generate, serve and display a vector tile map.

## Usage

`docker-compose up -d tegola`

## Importing data

### Local data

* Stop all existing instances: `sudo docker-compose down`
* Re-seed the `local` cache: `docker-compose up -d seed_local`
* Edit `.env` to match your environment and input-file (xxx.osm.pbf)
* Import xxx.osm.pbf: `docker-compose up -d import`
* Check progress and wait until done: `docker logs -f --tail 10 vectortiles_import_1`
* Apply post-processing (takes a while, thus `-d`): `docker-compose up -d postprocessing`
* Check progress and wait until done: `docker logs -f --tail 10 vectortiles_postprocessing_1`
* Remove all instances that are no longer needed: `sudo docker-compose down`

## DEM-References

- https://github.com/tilezen/joerd/blob/master/docs/use-service.md

## UI-References

- https://css-tricks.com/using-svg/
- https://yoksel.github.io/url-encoder/
