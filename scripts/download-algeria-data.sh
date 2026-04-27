#!/bin/bash

# Download Algerian OpenStreetMap Data from Geofabrik
# This script fetches the latest OSM data for Algeria

set -e

echo "=== Algerian OSM Data Download ==="
echo "Downloading latest Algeria OSM data from Geofabrik..."

# Create data directory if it doesn't exist
mkdir -p data

# Download the Algerian OSM data (PBF format)
# Algeria data is typically ~150-200MB
cd data

if [ ! -f "algeria-latest.osm.pbf" ]; then
    echo "Downloading algeria-latest.osm.pbf..."
    wget -q --show-progress https://download.geofabrik.de/africa/algeria-latest.osm.pbf
    echo "✓ Download complete"
else
    echo "✓ algeria-latest.osm.pbf already exists, skipping download"
fi

cd ..

echo ""
echo "=== Download Summary ==="
echo "✓ Algerian OSM data ready at: data/algeria-latest.osm.pbf"
echo ""
echo "Next step: Run 'npm run process-tiles' to generate MBTiles"
