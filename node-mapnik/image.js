#!/usr/bin/env node

// This example renders a static image from a stylesheet to disk

var mapnik = require('mapnik');
var fs = require('fs');
var path = require('path');

// register fonts and datasource plugins
mapnik.register_default_fonts();
if (mapnik.register_default_input_plugins) mapnik.register_default_input_plugins(); 

var map = new mapnik.Map(256, 256);
map.load('data/raster-stylesheet.xml', function(err,map) {
    if (err) throw err;
    map.zoomAll();
    var im = new mapnik.Image(256, 256);
    map.render(im, function(err,im) {
      if (err) throw err;
      im.encode('png', function(err,buffer) {
          if (err) throw err;
          fs.writeFile('out/map.png',buffer, function(err) {
              if (err) throw err;
              console.log('saved map image to map.png');
          });
      });
    });
});