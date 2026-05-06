# TileServer GL Setup Guide for Algerian OpenStreetMap Data

Complete guide to setting up a TileServer GL instance with Algerian OpenStreetMap data for use with React Native MapLibre.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Running TileServer GL](#running-tileserver-gl)
5. [Using with React Native](#using-with-react-native)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)

## System Requirements

### For local tile processing:
- Java 11+ (for Planetiler)
- Node.js 14+ (for scripts)
- 8GB RAM minimum (for Planetiler processing)
- 50GB free disk space (for OSM data and processed tiles)

### For TileServer GL:
- Node.js 14+
- 2GB RAM minimum
- Port 8080 available (or configure different port)

### For Docker deployment:
- Docker 20.10+
- Docker Compose 1.29+

## Quick Start

### Option 1: Local Development (Recommended for Testing)

```bash
# 1. Download Algerian OSM data
bash scripts/download-algeria-data.sh

# 2. (Optional) Download fonts for text rendering
# Skip if you want to use system fonts only

# 3. Install TileServer GL globally
npm install -g @mapbox/tileserver-gl-cli

# 4. Start TileServer with your MBTiles
tileserver-gl data/algeria.mbtiles \
  --styles osm-liberty-style.json \
  --port 8080
```

### Option 2: Docker Deployment (Recommended for Production)

```bash
# 1. Prepare your data
bash scripts/download-algeria-data.sh

# 2. Build and run with Docker Compose
docker-compose up --build

# TileServer will be available at http://localhost:8080
```

## Detailed Setup

### Step 1: Download Algerian OSM Data

The script downloads the latest OSM data from Geofabrik (~150-200MB):

```bash
bash scripts/download-algeria-data.sh
```

This creates:
- `data/algeria-latest.osm.pbf` - Raw OpenStreetMap data

**What this includes:**
- Roads, highways, and transport networks
- Buildings and structures
- Water bodies and landuse
- Administrative boundaries
- Points of interest (POIs)
- All publicly available OSM data for Algeria

### Step 2: Process OSM Data to Vector Tiles (Optional)

To generate custom MBTiles from the raw OSM data using Planetiler:

```bash
# First, install Planetiler (one time setup)
# Download from https://github.com/onthegomap/planetiler/releases

# Then run the processor
node scripts/process-tiles.js
```

Or use Java directly:

```bash
java -Xmx8g -jar planetiler.jar \
  --area=algeria \
  --output=data/algeria.mbtiles
```

**Processing time:** 30 minutes - 2 hours depending on system specs

**Output:** `data/algeria.mbtiles` (2-8GB depending on zoom levels)

### Step 3: Download Map Style

The repository includes `osm-liberty-style.json` which is a customized version of:
[OSM Bright GL Style](https://github.com/openmaptiles/osm-liberty-gl-style)

This style is pre-configured to work with your local TileServer.

### Step 4: Download and Setup Fonts (Optional)

For proper text rendering, download the OpenMapTiles fonts:

```bash
# Create fonts directory
mkdir -p data/fonts

# Download fonts (optional - TileServer can use system fonts as fallback)
# Fonts repository: https://github.com/openmaptiles/fonts
```

If you want to use custom fonts:

```bash
# Download a specific font package
curl -L https://github.com/openmaptiles/fonts/releases/download/v1.0/fonts.zip \
  -o /tmp/fonts.zip

# Extract to data/fonts
unzip /tmp/fonts.zip -d data/fonts
```

### Step 5: Configure TileServer GL

The `tileserver-gl-config.json` is pre-configured with:

```json
{
  "styles": {
    "osm-liberty": {
      "style": "osm-liberty-style.json",
      "tilejson": "2.2.0",
      "name": "OSM Bright - Algeria"
    }
  },
  "data": {
    "algeria": {
      "mbtiles": "data/algeria.mbtiles"
    }
  },
  "port": 8080,
  "allow_cors": true
}
```

## Running TileServer GL

### Method 1: Using npm/npx

```bash
# Install TileServer GL
npm install -g @mapbox/tileserver-gl-cli

# Run with your config
tileserver-gl --config tileserver-gl-config.json
```

### Method 2: Using Docker

```bash
# Build and run
docker-compose up

# Or build manually
docker build -t algeria-tileserver .
docker run -p 8080:8080 -v $(pwd)/data:/app/data algeria-tileserver
```

### Method 3: Using Node.js directly

```bash
# Install as dev dependency
npm install --save-dev @mapbox/tileserver-gl

# Run via npx
npx tileserver-gl --config tileserver-gl-config.json
```

### Verify Installation

Once running, check the following URLs:

```bash
# Main interface (web browser or curl)
curl http://localhost:8080

# Check available styles
curl http://localhost:8080/styles.json

# Check specific style
curl http://localhost:8080/styles/osm-liberty.json

# Check data sources
curl http://localhost:8080/data/algeria.json

# Check tile availability
curl http://localhost:8080/data/algeria/14/8602/5374.pbf
```

## Using with React Native

See [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md) for complete integration guide.

### Quick Integration Example

```jsx
import MapLibGL from '@react-native-mapbox-gl/maps';

const TILESERVER_URL = 'http://192.168.1.X:8080'; // Your server IP
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;

export default function AlgeriaMap() {
  return (
    <MapLibGL.MapView
      styleURL={STYLE_URL}
      centerCoordinate={[5.5, 28.0]}
      zoomLevel={4}
    />
  );
}
```

## Deployment

### Option 1: Docker (Recommended)

```bash
# Build image
docker build -t algeria-tileserver:latest .

# Push to registry (optional)
docker tag algeria-tileserver:latest your-registry/algeria-tileserver:latest
docker push your-registry/algeria-tileserver:latest

# Run container
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/data:/app/data \
  --name algeria-tileserver \
  algeria-tileserver:latest
```

### Option 2: Cloud Deployment

#### AWS EC2

```bash
# Launch instance with sufficient specs (t3.large or larger)
# 2GB+ RAM, 10GB+ storage

# Connect via SSH and:
sudo apt-get update
sudo apt-get install -y nodejs npm

npm install -g @mapbox/tileserver-gl-cli

# Copy your MBTiles and config
scp -r data/ ec2-user@your-instance:/home/ec2-user/
scp tileserver-gl-config.json osm-liberty-style.json ec2-user@your-instance:/home/ec2-user/

# Start TileServer
tileserver-gl --config tileserver-gl-config.json --port 8080
```

#### DigitalOcean App Platform

```yaml
# Create app.yaml
services:
- name: tileserver
  github:
    repo: your-username/planetiler-config-repo
    branch: main
  build_command: npm install -g @mapbox/tileserver-gl-cli
  run_command: tileserver-gl --config tileserver-gl-config.json --port 8080
  http_port: 8080
  resource:
    requests:
      memory: 2Gi
      cpu: 1000m
```

#### Vercel Serverless (Not Recommended)

TileServer GL requires persistent storage and background processes. Serverless is not ideal, but you can:

1. Use Vercel Blob or external storage for MBTiles
2. Keep a warm server or use cold-start container
3. Implement serverless tile rendering API

## Accessing Your TileServer

### Local Network
```
http://192.168.1.X:8080
```

### Remote Server
```
http://your-domain.com:8080
https://tileserver.your-domain.com
```

### Web Interface
```
http://localhost:8080
```

Shows:
- Available styles
- Data sources
- Vector tiles inspector
- TileJSON endpoints

## Configuration Options

### Custom Bounds
Edit `planetiler-config.json`:
```json
{
  "bounds": [2.0, 18.0, 9.0, 37.0]  // [minLon, minLat, maxLon, maxLat]
}
```

### Zoom Levels
```json
{
  "minzoom": 0,
  "maxzoom": 14
}
```

### Port Configuration
Edit `tileserver-gl-config.json`:
```json
{
  "port": 8080  // Change to different port
}
```

### CORS Settings
```json
{
  "allow_cors": true,
  "cors_url": "*"  // Restrict to specific origins if needed
}
```

## Performance Optimization

### Caching
```json
{
  "cache": 3600  // Cache tiles for 1 hour
}
```

### Compression
In Planetiler config:
```json
{
  "compress": "gzip"  // or "zstd" for better compression
}
```

### Layer Filtering
Only process necessary layers in style:
```json
{
  "layers": [
    "water",
    "road",
    "boundary",
    "place"
  ]
}
```

## Troubleshooting

### TileServer won't start

**Error:** `Error: EADDRINUSE: address already in use :::8080`

```bash
# Find and kill process using port 8080
lsof -i :8080
kill -9 <PID>

# Or change port in config
```

### MBTiles file not found

```bash
# Verify file exists
ls -lh data/algeria.mbtiles

# Ensure path in config is correct
cat tileserver-gl-config.json | grep mbtiles
```

### Tiles not displaying in React Native

1. Check network connectivity:
   ```bash
   curl http://192.168.1.X:8080/data/algeria.json
   ```

2. Verify style URL:
   ```bash
   curl http://192.168.1.X:8080/styles/osm-liberty.json
   ```

3. Check for CORS errors in React Native console

### Slow tile loading

1. Check disk I/O: `iostat -x 1`
2. Increase RAM allocation for TileServer
3. Verify network bandwidth
4. Enable caching in config

### Out of memory errors

**For Planetiler:**
```bash
java -Xmx16g -jar planetiler.jar ...  # Increase from 8g to 16g
```

**For TileServer:**
```bash
# Increase Node.js heap
node --max-old-space-size=4096 /usr/bin/tileserver-gl
```

## API Endpoints

### Styles
```
GET /styles.json                    # List all styles
GET /styles/{id}.json               # Get specific style
GET /styles/{id}/style.json         # Get full style spec
```

### Data
```
GET /data.json                      # List all data sources
GET /data/{id}.json                 # Get TileJSON for source
```

### Tiles
```
GET /data/{id}/{z}/{x}/{y}.pbf     # Vector tile (pbf)
GET /data/{id}/tilesets/{id}.json  # TileJSON metadata
```

### Fonts
```
GET /data/glyphs/{fontstack}/{range}.pbf
```

## References

- [TileServer GL Documentation](https://tileserver.readthedocs.io/)
- [Planetiler Documentation](https://docs.planetiler.org/)
- [OpenStreetMap Data](https://www.openstreetmap.org/)
- [Geofabrik Downloads](https://download.geofabrik.de/)
- [OpenMapTiles](https://openmaptiles.org/)
- [MapLibre Native](https://maplibre.org/maplibre-native/)
- [MapLibre GL JS Style Spec](https://maplibre.org/maplibre-gl-js-docs/style-spec/)

## License

- OpenStreetMap Data: [ODbL](https://opendatacommons.org/licenses/odbl/)
- OSM Bright Style: [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- This configuration: MIT License (unless otherwise specified)

## Support & Issues

For issues with this setup:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review logs: `docker logs algeria-tileserver`
3. Consult [TileServer GL Issues](https://github.com/maptiler/tileserver-gl/issues)
4. Report issues with your configuration in your project repo

## Next Steps

1. ✅ Download Algerian OSM data
2. ✅ Set up TileServer GL
3. → Integrate with React Native MapLibre (see REACT_NATIVE_SETUP.md)
4. → Deploy to production environment
5. → Monitor performance and optimize as needed
