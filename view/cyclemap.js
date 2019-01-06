var cyclemap = {
    "version": 8,
    "name": "Mapbox Local",
    "glyphs": "mapbox://fonts/mapbox/{fontstack}/{range}.pbf",
    "sources": {
        "global": {
            "type": "vector",
            "tiles": ["http://localhost:8080/maps/global/{z}/{x}/{y}.pbf?debug=true"],
        },
        "local": {
            "type": "vector",
            "tiles": ["http://localhost:8080/maps/local/{z}/{x}/{y}.pbf"],
        }
    },

    // Background
    "layers": [{
        "id": "background",
        "type": "background",
        "paint": {
            "background-color": "#f6f4e7"
        }
    },

    // Water
    {
        "id": "water_polygons_z2",
        "source": "global",
        "source-layer": "water_polygons_z2",
        "type": "fill",
        "paint": {
            "fill-color": "#7babcd", "fill-outline-color": "#7babcd"
        }
    },
    {
        "id": "water_polygons_z3",
        "source": "global",
        "source-layer": "water_polygons_z3",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "water_polygons_z4",
        "source": "global",
        "source-layer": "water_polygons_z4",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "water_polygons_z5",
        "source": "global",
        "source-layer": "water_polygons_z5",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "water_polygons_z6",
        "source": "global",
        "source-layer": "water_polygons_z6",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "water_polygons_z7",
        "source": "global",
        "source-layer": "water_polygons_z7",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "water_polygons_z8",
        "source": "global",
        "source-layer": "water_polygons_z8",
        "type": "fill",
        "paint": { "fill-color": "#7babcd", "fill-outline-color": "#7babcd" }
    },
    {
        "id": "simplified_water_polygons",
        "source": "global",
        "source-layer": "simplified_water_polygons",
        "type": "fill",
        "paint": {
            "fill-color": "#7babcd",
            "fill-outline-color": "rgba(192,0,0,0)"
        }
    },
    {
        "id": "water_polygons",
        "source": "global",
        "source-layer": "water_polygons",
        "type": "fill",
        "paint": {
            "fill-color": "#7babcd",
            "fill-outline-color": "rgba(192,0,0,0)"
        }
    },
    {
        "id": "global_debug",
        "source": "global",
        "source-layer": "debug_outline",
        "type": "line",
        "paint": {
            "line-color": "#FF0000",
            "line-width": 2
        }
    },
    // Admin
    {
        "id": "admin",
        "source": "local",
        "source-layer": "admin",
        "type": "line",
        "minzoom": 10,
        "paint": {
            "line-color": "#AA00AA",
            "line-width": 3
        }
    },
    // shiproute
    {
        "id": "shiproute",
        "source": "local",
        "source-layer": "shiproute",
        "type": "line",
        "minzoom": 10,
        "paint": {
            "line-color": "#1111AA",
            "line-width": 2
        }
    },
    {
        "id": "buildings",
        "source": "local",
        "source-layer": "buildings",
        "type": "fill",
        "paint": {
            "fill-color": "#444",
        }
    }
    ]
}