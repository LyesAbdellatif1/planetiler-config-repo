#!/bin/bash

set -e

echo "=== Algerian OSM Data Download ==="
echo "Downloading latest Algeria OSM data from Geofabrik..."

mkdir -p data
cd data

URL="https://download.geofabrik.de/africa/algeria-latest.osm.pbf"
FILE="algeria-latest.osm.pbf"

if [ ! -f "$FILE" ]; then
    echo "Downloading $FILE..."

    curl -L -o "$FILE" "$URL"

    echo "✓ Download complete"
else
    echo "✓ $FILE already exists, skipping download"
fi

cd ..

echo ""
echo "=== Download Summary ==="
echo "✓ Algerian OSM data ready at: data/$FILE"
echo ""
echo "Next step: Run 'npm run process-tiles' to generate MBTiles"