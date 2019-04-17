style=$(<cyclemap.json)

curl \
    --data-urlencode "style=${style}" \
    --data "height=512" \
    --data "width=512" \
    --data "center=10.5,47.7" \
    --data "zoom=10" \
    --data "token=pk.eyJ1IjoibXljeWNsZW1hcCIsImEiOiJjaXJhYnoxcGEwMDRxaTlubnk3cGZpbTBmIn0.TEO9UhyyX1nFKDTwO4K1xg" \
    http://localhost:81/render \
    --output test.png
