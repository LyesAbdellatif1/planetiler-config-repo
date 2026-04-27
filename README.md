# TileServer GL - Algerian OpenStreetMap

Complete setup for serving Algerian OpenStreetMap vector tiles with TileServer GL, configured for React Native MapLibre integration.

## 🎯 Overview

This repository provides a complete pipeline for:

1. **Downloading** Algerian OSM data from Geofabrik
2. **Processing** vector tiles using Planetiler
3. **Serving** tiles with TileServer GL
4. **Integrating** with React Native MapLibre applications

Built with:
- ✅ **Planetiler** - Vector tile generation from OSM data
- ✅ **TileServer GL** - High-performance tile server
- ✅ **OSM Bright Style** - Clean, customizable map style
- ✅ **Maki Icons** - 600+ map icons and sprites
- ✅ **OpenMapTiles** - Standardized tile schema
- ✅ **Docker** - Easy deployment

## 📋 Quick Start

### Option 1: Local Development (5 minutes)

```bash
# 1. Download Algerian OSM data (~200MB, 5 mins)
bash scripts/download-algeria-data.sh

# 2. Download sprites and icons (Maki icon set)
npm run sprites

# 3. Install TileServer GL
npm install -g @mapbox/tileserver-gl-cli

# 4. Start serving tiles
npm run tileserver
```

Then access at: `http://localhost:8080`

### Option 2: Docker (Recommended)

```bash
# Download data
bash scripts/download-algeria-data.sh

# Start with Docker Compose
docker-compose up --build

# Access at http://localhost:8080
```

## 📁 Directory Structure

```
.
├── scripts/
│   ├── download-algeria-data.sh    # Download OSM data from Geofabrik
│   ├── download-fonts.sh            # Download OpenMapTiles fonts
│   ├── setup-sprites.sh             # Download sprites and Maki icons
│   └── process-tiles.js             # Generate MBTiles from OSM data
├── data/
│   ├── algeria-latest.osm.pbf      # Raw OSM data (downloaded)
│   ├── algeria.mbtiles              # Vector tiles (generated)
│   ├── fonts/                       # Font files for text rendering
│   ├── sprites/                     # Icon sprites (Maki icons)
│   └── icons/                       # Icon definitions and categories
├── docs/
│   └── REACT_NATIVE_SETUP.md        # React Native integration guide
├── osm-bright-style.json            # Customized map style
├── tileserver-gl-config.json        # TileServer GL configuration
├── planetiler-config.json           # Planetiler processing config
├── TILESERVER_SETUP.md              # Detailed setup guide
├── Dockerfile                       # Docker image configuration
└── docker-compose.yml               # Multi-container setup
```

## 🚀 Setup Steps

### Step 1: Download Data

```bash
bash scripts/download-algeria-data.sh
```

Downloads `algeria-latest.osm.pbf` (~150-200MB) from Geofabrik.

**Includes:**
- Roads, highways, and transport
- Buildings and structures
- Water bodies and landuse
- Administrative boundaries
- Points of interest (POIs)

### Step 2: Process Tiles (Optional)

If you need to generate custom MBTiles:

```bash
# Install Java (if not already installed)
# macOS: brew install openjdk
# Ubuntu: sudo apt-get install openjdk-11-jdk

# Download Planetiler JAR
# From: https://github.com/onthegomap/planetiler/releases

# Process tiles (takes 30 min - 2 hours)
java -Xmx8g -jar planetiler.jar --area=algeria --output=data/algeria.mbtiles
```

### Step 3: Download Fonts (Optional)

For better text rendering:

```bash
bash scripts/download-fonts.sh
```

Downloads OpenMapTiles fonts for multilingual support.

### Step 4: Start TileServer GL

**Local (without Docker):**
```bash
npm install -g @mapbox/tileserver-gl-cli
tileserver-gl --config tileserver-gl-config.json
```

**With Docker:**
```bash
docker-compose up
```

**With npm:**
```bash
npm run tileserver
```

### Step 5: Integrate with React Native

See [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md)

Quick example:
```jsx
import MapLibGL from '@react-native-mapbox-gl/maps';

export default function AlgeriaMap() {
  return (
    <MapLibGL.MapView
      styleURL="http://192.168.1.X:8080/styles/osm-bright/style.json"
      centerCoordinate={[5.5, 28.0]}
      zoomLevel={4}
    />
  );
}
```

## 📦 Available npm Scripts

```bash
npm run download      # Download Algerian OSM data
npm run fonts        # Download OpenMapTiles fonts
npm run sprites      # Download sprites and Maki icons (600+ icons)
npm run tileserver   # Start TileServer GL
npm run setup        # Complete setup (download data + sprites)
npm run verify       # Verify all components are installed
npm run docker-build # Build Docker image
npm run docker-up    # Start Docker containers
npm run docker-down  # Stop Docker containers
```

## 🗺️ Map Coverage

**Geographic Area:** Algeria
- **Coordinates:** 2.0°E - 9.0°E, 18.0°N - 37.0°N
- **Zoom Levels:** 0 - 14
- **Data Source:** OpenStreetMap via Geofabrik

**Major Cities Covered:**
- Algiers (Alger)
- Oran
- Constantine
- Annaba
- Tlemcen
- And 100+ other cities/towns

## 🎨 Included Style & Icons

### OSM Bright Style
Clean, bright map style with:
- Clear road hierarchy
- Building footprints at high zoom
- Water and landuse features
- Multilingual place labels
- Optimal for mobile viewing

Customizable via `osm-bright-style.json`

### Maki Icons & Sprites
The setup includes **600+ Maki icons** from MapBox for rendering POIs:

**Icon Categories:**
- 🍽️ **Food & Drink** - Restaurants, cafes, bars, bakeries
- 🛍️ **Shops** - Retail stores, supermarkets, specialty shops
- 🏦 **Finance** - Banks, ATMs, currency exchange
- 💊 **Health** - Hospitals, pharmacies, clinics
- 🚗 **Transport** - Parking, fuel, bus, train, airport
- 🏨 **Accommodation** - Hotels, hostels, guest houses
- 🎭 **Entertainment** - Museums, attractions, theaters
- 📚 **Education** - Schools, universities, libraries
- 🏛️ **Services** - Post offices, police, fire stations
- 🌳 **Nature** - Parks, viewpoints, hiking trails

**Features:**
- Standard (15px) and high-resolution (@2x) versions
- Automatic Retina/high-DPI support
- 600+ pre-made icons
- Zoom-based icon sizing
- Dynamic color support
- Full MapLibre GL integration

Setup with:
```bash
npm run sprites
```

**Documentation:**
- [SPRITES_AND_ICONS.md](./docs/SPRITES_AND_ICONS.md) - Comprehensive sprite guide
- [ICON_REFERENCE.md](./docs/ICON_REFERENCE.md) - Complete icon catalog
- [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md) - React Native integration examples

## 🔧 Configuration

### TileServer GL Config

Edit `tileserver-gl-config.json`:

```json
{
  "port": 8080,
  "allow_cors": true,
  "cache": 3600,
  "styles": {
    "osm-bright": { /* style config */ }
  }
}
```

### Planetiler Config

Edit `planetiler-config.json` to customize:
- Zoom levels
- Layer composition
- Tile bounds
- Compression

### Style Customization

Edit `osm-bright-style.json` to:
- Change colors and fonts
- Add/remove layers
- Adjust feature visibility

## 📱 React Native Integration

### Requirements

```bash
npm install @react-native-mapbox-gl/maps
npm install react-native-gesture-handler
npm install @react-native-community/geolocation
```

### Basic Example

```jsx
import React from 'react';
import { View, StyleSheet } from 'react-native';
import MapLibGL from '@react-native-mapbox-gl/maps';

const STYLE_URL = 'http://192.168.1.X:8080/styles/osm-bright/style.json';

export default function App() {
  return (
    <View style={styles.container}>
      <MapLibGL.MapView
        style={styles.map}
        styleURL={STYLE_URL}
        centerCoordinate={[5.5, 28.0]}
        zoomLevel={4}
      >
        <MapLibGL.Camera
          centerCoordinate={[5.5, 28.0]}
          zoomLevel={4}
        />
      </MapLibGL.MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },
});
```

See [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md) for more examples.

## 🚢 Deployment

### Docker (Recommended)

```bash
# Build image
docker build -t algeria-tileserver:latest .

# Run container
docker run -d -p 8080:8080 -v $(pwd)/data:/app/data algeria-tileserver

# Or use Docker Compose
docker-compose up -d
```

### Cloud Platforms

- **AWS EC2:** Deploy with t3.large or larger instance
- **DigitalOcean:** Use App Platform or Droplets
- **Heroku:** Use [tileserver-gl-light](https://github.com/klokantech/tileserver-gl-light)
- **VPS:** Any Linux server with Docker support

See [TILESERVER_SETUP.md](./TILESERVER_SETUP.md) for detailed deployment guides.

## 📊 Performance

Typical performance on t3.large EC2 instance:

- **Tile serving:** < 50ms per tile
- **Concurrent requests:** 1000+ per second
- **Memory usage:** ~500MB base + tile cache
- **Disk I/O:** Efficient with MBTiles format

## 🔍 API Endpoints

```
GET /                              # Web interface
GET /styles.json                   # Available styles
GET /styles/{id}.json              # Style metadata
GET /data.json                     # Available data
GET /data/{id}/tilesets/{id}.json  # TileJSON spec
GET /data/{id}/{z}/{x}/{y}.pbf     # Vector tiles
GET /data/glyphs/{font}/{range}    # Font glyphs
```

## ❓ Troubleshooting

### Issue: "MBTiles file not found"

```bash
# Check if file exists
ls -lh data/algeria.mbtiles

# Download pre-processed tiles or run Planetiler
bash scripts/download-algeria-data.sh
```

### Issue: "Tiles not displaying in React Native"

1. Verify TileServer is running: `curl http://localhost:8080`
2. Check network connectivity from device
3. Verify style URL format: `http://IP:8080/styles/osm-bright/style.json`
4. Enable CORS in config: `"allow_cors": true`

### Issue: "Port 8080 already in use"

```bash
# Find process using port
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or change port in config
```

See [TILESERVER_SETUP.md](./TILESERVER_SETUP.md#troubleshooting) for more solutions.

## 📚 Documentation

- **[TILESERVER_SETUP.md](./TILESERVER_SETUP.md)** - Complete setup and deployment guide
- **[REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md)** - React Native integration examples
- **[Planetiler Docs](https://docs.planetiler.org/)** - Tile generation documentation
- **[TileServer GL Docs](https://tileserver.readthedocs.io/)** - Server configuration reference

## 🔗 Resources

- [OpenStreetMap](https://www.openstreetmap.org/) - Data source
- [Geofabrik](https://download.geofabrik.de/) - OSM extracts
- [Planetiler](https://github.com/onthegomap/planetiler) - Tile generation
- [TileServer GL](https://github.com/maptiler/tileserver-gl) - Tile server
- [OpenMapTiles](https://openmaptiles.org/) - Tile schema
- [MapLibre](https://maplibre.org/) - Open-source mapping libraries

## 📜 License

- **OSM Data:** [Open Data Commons ODbL 1.0](https://opendatacommons.org/licenses/odbl/)
- **OSM Bright Style:** [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/)
- **Configuration & Scripts:** MIT License
- **Planetiler:** [Apache 2.0](https://github.com/onthegomap/planetiler/blob/main/LICENSE.md)

## 🤝 Contributing

Improvements welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📞 Support

For issues or questions:

1. Check [TILESERVER_SETUP.md](./TILESERVER_SETUP.md#troubleshooting) troubleshooting section
2. Review [TileServer GL Issues](https://github.com/maptiler/tileserver-gl/issues)
3. Consult [Planetiler Documentation](https://docs.planetiler.org/)
4. Open an issue in this repository

## 🎓 Learning Resources

- [Vector Tiles Explained](https://openmaptiles.org/docs/)
- [Mapbox Style Specification](https://maplibre.org/maplibre-gl-js/docs/API/types/StyleSpecification/)
- [OpenStreetMap Wiki](https://wiki.openstreetmap.org/)
- [MapLibre Native Guide](https://maplibre.org/maplibre-native/)

---

Built for serving beautiful Algerian maps with open data. 🇩🇿
