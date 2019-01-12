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
        "id": "water",
        "source": "global",
        "source-layer": "water",
        "type": "fill",
        "paint": {
            "fill-color": "#7babcd",
            "fill-opacity-transition": {duration: 2000},
            "fill-outline-color": "rgba(192,0,0,0)"
        }
    },
    // Admin
    {
        "id": "admin",
        "source": "local",
        "source-layer": "admin",
        "type": "line",
        "minzoom": 11,
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
            "line-dasharray": [5, 5],
            "line-width": 2.4
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