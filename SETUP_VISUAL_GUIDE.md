# TileServer GL - Visual Setup Guide

A visual walkthrough of setting up your Algerian tile server.

## The Big Picture

```
YOUR ALGERIAN MAP DATA
         ↓
   [Download OSM]
         ↓
  OSM PBF Data (200MB)
         ↓
   [Planetiler] ← [Optional] Process to MBTiles
         ↓
   MBTiles File (2-8GB)
         ↓
  [TileServer GL] ← Serves on :8080
         ↓
   REST API Endpoints
         ↓
  React Native + MapLibre
         ↓
  Beautiful Maps! 🗺️
```

## Quick 5-Step Setup

### Step 1️⃣ Download Data (3 min)
```bash
$ bash scripts/download-algeria-data.sh
```
**What happens:** Downloads `algeria-latest.osm.pbf` (~200MB) from Geofabrik
```
📥 Downloading algeria-latest.osm.pbf...
✓ Download complete
```

### Step 2️⃣ Install TileServer (1 min)
```bash
$ npm install -g @mapbox/tileserver-gl-cli
```
**What happens:** Installs tile server globally so you can run it anywhere

### Step 3️⃣ Start Server (instant)
```bash
$ npm run tileserver
```
**What happens:**
```
[14:32] Starting TileServer GL v4.8.0
[14:32] Listening on port http://localhost:8080
```

### Step 4️⃣ View in Browser
Open: **http://localhost:8080**

### Step 5️⃣ Use in React Native
```jsx
<MapLibGL.MapView
  styleURL="http://192.168.1.X:8080/styles/osm-liberty/style.json"
  centerCoordinate={[5.5, 28.0]}
  zoomLevel={4}
/>
```

---

## Directory Structure at a Glance

```
your-project/
│
├── 📄 README.md                    ← Start here!
├── 📄 QUICKSTART.md                ← Fast 5-min setup
├── 📄 TILESERVER_SETUP.md          ← Detailed guide
├── 📄 IMPLEMENTATION.md            ← What's included
│
├── 📁 scripts/
│   ├── download-algeria-data.sh   ← Downloads OSM data
│   ├── download-fonts.sh          ← Downloads fonts
│   ├── process-tiles.js           ← Generates MBTiles (optional)
│   └── verify-setup.sh            ← Checks prerequisites
│
├── 📁 data/                        ← Your tile data lives here
│   ├── algeria-latest.osm.pbf    ← Downloaded OSM data (200MB)
│   ├── algeria.mbtiles            ← Generated tiles (2-8GB, optional)
│   └── fonts/                     ← Font files (optional)
│
├── 📁 docs/
│   └── REACT_NATIVE_SETUP.md      ← React Native guide + examples
│
├── ⚙️  config.json                  ← Original Planetiler config
├── 🎨 osm-liberty-style.json        ← Map style (edit this to customize!)
├── 🔧 tileserver-gl-config.json    ← Server configuration
├── ⚙️  planetiler-config.json      ← Tile generation config
│
├── 🐳 Dockerfile                   ← Docker container
├── 🐳 docker-compose.yml           ← Docker multi-container
│
└── 📦 package.json                ← NPM configuration
```

---

## What Each File Does

### Data Files (in `data/` folder)
| File | Size | What it is | Required? |
|------|------|-----------|-----------|
| `algeria-latest.osm.pbf` | 200MB | Raw OpenStreetMap data | ✅ YES |
| `algeria.mbtiles` | 2-8GB | Processed vector tiles | Optional |
| `fonts/` | 50MB | Text rendering fonts | Optional |

### Configuration Files
| File | Purpose |
|------|---------|
| `tileserver-gl-config.json` | How TileServer GL behaves (port, caching, etc) |
| `osm-liberty-style.json` | How the map looks (colors, fonts, layers) |
| `planetiler-config.json` | How to process OSM data |
| `docker-compose.yml` | Docker setup |

### Documentation
| File | When to read |
|------|-------------|
| `README.md` | First thing - overview & features |
| `QUICKSTART.md` | Want it running in 5 mins |
| `TILESERVER_SETUP.md` | Need complete setup details |
| `docs/REACT_NATIVE_SETUP.md` | Building React Native apps |
| `IMPLEMENTATION.md` | Want to understand what's included |

---

## What Happens When You Run Commands

### `bash scripts/download-algeria-data.sh`
```
Creating data directory...
Downloading algeria-latest.osm.pbf from Geofabrik...
[████████████████████████] 100% (200MB)
✓ Download complete
✓ Algerian OSM data ready at: data/algeria-latest.osm.pbf
```

### `npm run tileserver`
```
Starting TileServer GL...
Configuring from: tileserver-gl-config.json
Loading MBTiles: data/algeria.mbtiles
Loading style: osm-liberty-style.json
Starting HTTP server on port 8080...
✓ TileServer GL running at http://localhost:8080
```

### `npm run docker-up`
```
Building Docker image...
[████████████████████████] 100%
Starting containers...
✓ tileserver container started
✓ Accessible at http://localhost:8080
```

---

## React Native Integration Flow

```
┌─────────────────────────────────────────────────┐
│  Your React Native App                          │
│  ┌──────────────────────────────────────────┐   │
│  │ import MapLibGL from '@react-native...  │   │
│  │                                          │   │
│  │ <MapLibGL.MapView                       │   │
│  │   styleURL={TILESERVER_URL}             │   │
│  │   centerCoordinate={[5.5, 28.0]}        │   │
│  │ />                                       │   │
│  └───────────────────┬──────────────────────┘   │
└─────────────────────┼──────────────────────────┘
                      │
                      │ Requests
                      ↓
          ┌───────────────────────────┐
          │  TileServer GL (Port 8080)│
          │                           │
          │ Sends:                    │
          │ - Vector tiles (PBF)      │
          │ - Style JSON              │
          │ - Fonts                   │
          └───────────────┬───────────┘
                          │
                          │ Uses
                          ↓
               ┌────────────────────┐
               │  MBTiles Database  │
               │ (algeria.mbtiles)  │
               └────────────────────┘
```

---

## Common Tasks

### "I want to start the server"
```bash
npm run tileserver
# Then open http://localhost:8080
```

### "I want to use it in React Native"
See: `docs/REACT_NATIVE_SETUP.md` (has 3 complete examples)

### "I want to customize the map colors"
Edit: `osm-liberty-style.json` (just save and refresh)

### "I want to use Docker"
```bash
npm run docker-up    # Start
npm run docker-logs  # View logs
npm run docker-down  # Stop
```

### "Port 8080 is already in use"
Option 1: Change port in `tileserver-gl-config.json`
Option 2: Kill the process: `lsof -i :8080` then `kill -9 <PID>`

### "Verify everything is installed"
```bash
bash scripts/verify-setup.sh
```

### "Download fonts for better text"
```bash
bash scripts/download-fonts.sh
```

---

## API Endpoints Once Running

Once TileServer is running at `http://localhost:8080`:

```
🌐 WEB INTERFACE
  http://localhost:8080
  → See tiles, stats, and inspector

🗺️  STYLES
  http://localhost:8080/styles.json
  → List available styles
  
  http://localhost:8080/styles/osm-liberty/style.json
  → Full style specification

📍 TILES
  http://localhost:8080/data/algeria/{z}/{x}/{y}.pbf
  → Vector tiles (z=zoom, x=column, y=row)
  
  Examples:
  http://localhost:8080/data/algeria/4/8/5.pbf    (zoom 4)
  http://localhost:8080/data/algeria/10/520/340.pbf (zoom 10)

🔤 FONTS
  http://localhost:8080/data/glyphs/{font}/{range}.pbf
  → Font glyphs for text rendering
```

---

## Network Access

### Local Computer Only
```
http://localhost:8080
```

### Other devices on Same Network
```
http://192.168.1.X:8080
# Replace 192.168.1.X with your computer's IP
# Find IP with: ipconfig (Windows) or ifconfig (Mac/Linux)
```

### From Internet (Need to Deploy)
```
https://your-domain.com:8080
# See TILESERVER_SETUP.md for deployment
```

---

## Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| "Port 8080 in use" | Change port in config or kill process |
| "MBTiles not found" | Run `bash scripts/download-algeria-data.sh` |
| "Tiles not loading in React Native" | Use computer IP instead of localhost |
| "Can't download OSM data" | Check internet connection |
| "Docker won't start" | Check `npm run docker-logs` for errors |
| "Style changes not showing" | Refresh browser/app |

See `TILESERVER_SETUP.md` for detailed troubleshooting.

---

## Data Coverage

Your tiles cover all of Algeria:

```
          MEDITERRANEAN SEA
  ════════════════════════════════════
   Tunisia │ Algeria │ Libya
          2°E                    9°E
  
  37°N ┌─────────────────────────┐ 37°N
       │                         │
  32°N │      ALGERIA            │ 32°N
       │                         │
  27°N │                         │ 27°N
       │                         │
  22°N │                         │ 22°N
       │                         │
  18°N └─────────────────────────┘ 18°N
          2°E              9°E
  
  Includes:
  ✓ Algiers, Oran, Constantine, Annaba
  ✓ All major cities and towns
  ✓ Complete road network
  ✓ Water features and landuse
  ✓ All administrative boundaries
```

---

## Next Steps

### Today ✅
1. Run setup verification: `bash scripts/verify-setup.sh`
2. Download data: `bash scripts/download-algeria-data.sh`
3. Start server: `npm run tileserver`
4. View at: `http://localhost:8080`

### This Week 📅
1. Test in React Native app
2. Customize map style (colors, fonts)
3. Download fonts for better text

### This Month 🚀
1. Deploy to production
2. Set up monitoring
3. Integrate with your apps

---

## Questions?

1. Check the full guides: `README.md`, `TILESERVER_SETUP.md`
2. See React Native examples: `docs/REACT_NATIVE_SETUP.md`
3. Troubleshooting: `TILESERVER_SETUP.md#Troubleshooting`

**You're all set! Happy mapping! 🗺️**
