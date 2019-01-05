#!/usr/bin/env node
"use strict"

// This example shows how to use node-mapnik to render and serve vector tiles

var mapnik = require('mapnik');
var http = require('http');
var path = require('path');
var url = require('url');

var port = 8000;
var vector_stylesheet = path.join(__dirname, 'data/vector-stylesheet.xml');
var raster_stylesheet = path.join(__dirname, 'data/raster-stylesheet.xml');
// register shapefile plugin
if (mapnik.register_default_input_plugins) mapnik.register_default_input_plugins();


// some coordinate transformation functions
// see https://www.maptiler.com/google-maps-coordinates-tile-bounds-projection/
function GlobalMercator(tileSize=256) {
    this.tileSize = tileSize;
    this.initialResolution = 2 * Math.PI * 6378137 / this.tileSize;
    this.originShift = 2 * Math.PI * 6378137 / 2.0
}

GlobalMercator.prototype.PixelsToMeters = function(px, py, zoom) {
    var res = this.initialResolution / Math.pow(2, zoom)
    var mx = px * res - this.originShift
    var my = py * res - this.originShift
    return [mx, my]
};

GlobalMercator.prototype.TileBounds = function(tx, ty, zoom) {
    ty = (Math.pow(2, zoom) - 1) - ty
    var minx_miny = this.PixelsToMeters( tx*this.tileSize, ty*this.tileSize, zoom )
    var maxx_maxy = this.PixelsToMeters( (tx+1)*this.tileSize, (ty+1)*this.tileSize, zoom )
    return minx_miny.concat(maxx_maxy)
};

var mercator = new GlobalMercator();

http.createServer(function (req, res) {
    var map = new mapnik.Map(256, 256);
    var query = url.parse(req.url, true).query;
    if (query.type === "vector") {
        map.load(vector_stylesheet, function (err, map) {
            if (err) {
                return res.end(err.message);
            }

            var im = new mapnik.VectorTile(parseInt(query.z, 0), parseInt(query.x, 0), parseInt(query.y, 0));
            console.log("[server] - rendering VectorTile (", query.z, query.x, query.y, ")")
            map.render(im, function (err, vtile) {
                if (err) {
                    res.end(err.message);
                }
                else {
                    // IMPORTANT: setting Access-Control-Allow-Origin is mandatory. Otherwise you will get CORS-Errors in your browser
                    res.writeHead(200, { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'application/x-protobuf' });
                    res.end(vtile.getData());
                }
            });
        });
    }
    else if(query.type === "raster") {
        map.load(raster_stylesheet, function (err, map) {
            if (err) {
                return res.end(err.message);
            }
            var bbox = mercator.TileBounds(parseInt(query.x, 0), parseInt(query.y, 0), parseInt(query.z, 0));
            // bbox = [5009377.085697311, 0.03784862651052282, 10018754.133545995, 5009377.085753322]
            map.extent = bbox
            // map.zoomAll();                 
            var im = new mapnik.Image(256, 256);
            console.log("[server] - rendering PNG Image (", query.z, query.x, query.y, ")")
            map.render(im, function (err, im) {
                if (err) {
                    res.end(err.message);
                }
                else {
                    // IMPORTANT: setting Access-Control-Allow-Origin is mandatory. Otherwise you will get CORS-Errors in your browser
                    res.writeHead(200, { 'Access-Control-Allow-Origin': '*', 'Content-Type': 'image/png' });
                    res.end(im.encodeSync('png'));
                }
            });
        });
    }
}).listen(port);

console.log('[server] - running on port ' + port);
