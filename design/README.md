# Map design guidelines

## General

- Avoid using transparency as that leads to 

## Polygon/Fill
- Use the same outline color as the feature itself. Do not set outline color to transparent as that leads to visual artefacts at nearby polygon  seams.

## Generalized data

## Sprites

```
cd design/sprites
docker run --rm -ti -v $(pwd):/sprites afrith/node-mapnik:latest bash
 npm install -g @mapbox/spritezero-cli
 cd /sprites
 spritezero cyclemap src/
 spritezero --ratio=2 cyclemap@2x src/
 spritezero --ratio=4 cyclemap@4x src/
```

## References


