#!/usr/bin/env node

// This example renders a static vector-tile from a stylesheet and writes it to disk

var mapnik = require('mapnik');
var fs = require('fs');

// register fonts and datasource plugins
mapnik.register_default_fonts();
mapnik.register_default_input_plugins();

var map = new mapnik.Map(256, 256);
map.load('data/stylesheet.xml', function (err, map) {
    if (err) throw err;
    map.zoomAll();

    // zoom=0, x=0, y=0
    var im = new mapnik.VectorTile(0, 0, 0);

    map.render(im, function (err, vtile) {
        if (err) throw err;

        fs.writeFile('out/map.pbf', vtile.getData(), function (err) {
            if (err) throw err;
            console.log('saved map image to map.pbf');
        });

        fs.writeFile('out/map.geojson', vtile.toGeoJSON(0), function (err) {
            if (err) throw err;
            console.log('saved map image to map.geojson');
        });
    });
});