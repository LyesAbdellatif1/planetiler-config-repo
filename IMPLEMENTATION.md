# Implementation Summary - TileServer GL for Algerian OpenStreetMap

Complete implementation of a production-ready tileserver for serving Algerian OpenStreetMap data with React Native MapLibre integration.

## What Was Built

A full pipeline from raw OSM data to a running tile server:

```
OSM Data (Geofabrik)
      │
      ▼
Planetiler (Docker)  ←── also downloads: lake centerlines, water polygons, Natural Earth
      │
      ▼
algeria.mbtiles  (206 MB vector tile database)
      │
      ▼
TileServer GL (Docker: maptiler/tileserver-gl)
      │  serves:
      ├── /data/algeria/{z}/{x}/{y}.pbf   vector tiles
      ├── /styles/osm-liberty/style.json   map style
      ├── /fonts/{fontstack}/{range}.pbf   text glyphs
      └── /sprites/osm-liberty.*           map icons
      │
      ▼
React Native / Browser  (MapLibre GL)
```

---

## Scripts Reference (Windows PowerShell)

All scripts are in `scripts/`. On Windows, use the `.ps1` versions — the `.sh` files require WSL or Git Bash.

| Task | Command |
|------|---------|
| Download OSM data | `powershell -ExecutionPolicy Bypass -File scripts/download-algeria-data.ps1` |
| Download sprites | `powershell -ExecutionPolicy Bypass -File scripts/setup-sprites.ps1` |
| Download fonts | `powershell -ExecutionPolicy Bypass -File scripts/download-fonts.ps1` |
| Generate MBTiles | `powershell -ExecutionPolicy Bypass -File scripts/run-planetiler.ps1` |
| Start server | `docker-compose up` |

### What each script does

**`scripts/download-algeria-data.ps1`**
- Downloads `algeria-latest.osm.pbf` (~283 MB) from Geofabrik
- Saves to `data/algeria-latest.osm.pbf`

**`scripts/setup-sprites.ps1`**
- Downloads 4 sprite files from `openmaptiles/osm-liberty-gl-style` (gh-pages branch)
- Saves to `data/sprites/`: `osm-liberty.json`, `osm-liberty.png`, `osm-liberty@2x.json`, `osm-liberty@2x.png`
- Also creates `data/icons/`: `iconset.json`, `categories.json`, `poi-layers.json`

**`scripts/download-fonts.ps1`**
- Downloads `noto-open-sans.zip` (~64 MB) from `openmaptiles/fonts` v2.0
- Extracts 2560 `.pbf` glyph files into `data/fonts/`
- Provides Open Sans + Noto Sans font families

**`scripts/run-planetiler.ps1`**
- Pulls `ghcr.io/onthegomap/planetiler:latest` Docker image (no Java needed)
- Mounts `data/` into the container
- Reads `data/algeria-latest.osm.pbf`
- Auto-downloads 3 additional required sources into `data/sources/`:
  - `lake_centerline.shp.zip`
  - `water-polygons-split-3857.zip`
  - `natural_earth_vector.sqlite.zip`
- Outputs `data/algeria.mbtiles` (206 MB, zooms 0-14)

---

## File Structure and Connections

```
planetiler-config-repo/
│
├── docker-compose.yml              ← starts TileServer GL
│     uses image: maptiler/tileserver-gl:latest
│     mounts:
│       ./data                          → /data
│       ./tileserver-gl-config.json     → /data/config.json
│       ./osm-liberty-style.json        → /data/osm-liberty-style.json
│
├── tileserver-gl-config.json       ← server configuration
│     paths.root    = /data
│     paths.fonts   = fonts         → /data/fonts/
│     paths.sprites = sprites       → /data/sprites/
│     paths.mbtiles = ""            → /data/
│     styles.osm-liberty.style = osm-liberty-style.json
│     data.algeria.mbtiles    = algeria.mbtiles
│
├── osm-liberty-style.json          ← map appearance
│     sources.openmaptiles.url = "mbtiles://algeria"
│       └── resolved by tileserver to /data/algeria.mbtiles
│     sprite = "http://localhost:8080/sprites/osm-liberty"
│       └── served from /data/sprites/osm-liberty.*
│     glyphs = "http://localhost:8080/fonts/{fontstack}/{range}.pbf"
│       └── served from /data/fonts/{family}/{range}.pbf
│
├── data/
│   ├── algeria-latest.osm.pbf      ← raw OSM input (283 MB)
│   ├── algeria.mbtiles             ← generated vector tiles (206 MB)
│   ├── fonts/                      ← 2560 .pbf glyph files
│   │   ├── Open Sans Regular/
│   │   ├── Open Sans Bold/
│   │   ├── Noto Sans Regular/
│   │   └── ...
│   ├── sprites/                    ← icon sprite sheets
│   │   ├── osm-liberty.json
│   │   ├── osm-liberty.png
│   │   ├── osm-liberty@2x.json
│   │   └── osm-liberty@2x.png
│   ├── icons/                      ← POI category mappings
│   │   ├── categories.json
│   │   ├── iconset.json
│   │   └── poi-layers.json
│   └── sources/                    ← Planetiler auxiliary downloads
│       ├── lake_centerline.shp.zip
│       ├── water-polygons-split-3857.zip
│       └── natural_earth_vector.sqlite.zip
│
└── scripts/
    ├── run-planetiler.ps1          ← MBTiles generation (Docker)
    ├── setup-sprites.ps1           ← download sprite files
    ├── download-fonts.ps1          ← download font glyphs
    └── download-algeria-data.ps1   ← download OSM data
```

---

## Docker Setup

### TileServer GL (serving tiles)

Uses the official `maptiler/tileserver-gl` image — no custom build needed.

```yaml
# docker-compose.yml
services:
  tileserver:
    image: maptiler/tileserver-gl:latest
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
      - ./tileserver-gl-config.json:/data/config.json
      - ./osm-liberty-style.json:/data/osm-liberty-style.json
```

Start: `docker-compose up`

### Planetiler (generating MBTiles)

Uses `ghcr.io/onthegomap/planetiler:latest` — run once, not part of docker-compose.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-planetiler.ps1
```

---

## API Endpoints

Once `docker-compose up` is running at `http://localhost:8080`:

| Endpoint | Description |
|----------|-------------|
| `/` | TileServer GL web UI |
| `/styles/osm-liberty/style.json` | Full map style JSON |
| `/data/algeria.json` | TileJSON metadata |
| `/data/algeria/{z}/{x}/{y}.pbf` | Vector tiles |
| `/fonts/{fontstack}/{range}.pbf` | Font glyphs |
| `/sprites/osm-liberty.json` | Sprite metadata |
| `/sprites/osm-liberty.png` | Sprite image |

---

## TileServer GL Config Reference

```json
{
  "options": {
    "paths": {
      "root": "/data",
      "fonts": "fonts",
      "sprites": "sprites",
      "styles": "",
      "mbtiles": ""
    }
  },
  "styles": {
    "osm-liberty": {
      "style": "osm-liberty-style.json"
    }
  },
  "data": {
    "algeria": {
      "mbtiles": "algeria.mbtiles"
    }
  }
}
```

Path resolution: all relative paths are resolved from `root` (`/data`).

---

## Style File Reference

Key fields in `osm-liberty-style.json`:

```json
{
  "version": 8,
  "sources": {
    "openmaptiles": {
      "type": "vector",
      "url": "mbtiles://algeria"
    }
  },
  "sprite": "http://localhost:8080/sprites/osm-liberty",
  "glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf",
  "center": [5.5, 28.0],
  "zoom": 4
}
```

- `mbtiles://algeria` — resolved by TileServer GL to the `algeria` entry in config (`algeria.mbtiles`)
- `sprite` — must match the sprite files in `data/sprites/`
- `glyphs` — must use `/fonts/` path (not `/data/glyphs/`)
- `center` — exactly 2 values `[lon, lat]`; zoom is a separate field

---

## React Native Integration

In your MapLibre React Native app, point to the style URL:

```js
const styleURL = 'http://<server-ip>:8080/styles/osm-liberty/style.json';
```

Replace `<server-ip>` with your machine's local IP (e.g. `192.168.1.100`). All sprites, fonts, and tiles load automatically from the style.

For Arabic label support add the RTL plugin:

```js
import MapLibreGL from '@maplibre/maplibre-react-native';
MapLibreGL.setRTLTextPlugin(
  'https://unpkg.com/@mapbox/mapbox-gl-rtl-text@0.2.3/mapbox-gl-rtl-text.min.js'
);
```

See [docs/REACT_NATIVE_SETUP.md](docs/REACT_NATIVE_SETUP.md) for complete examples.

---

## Documentation Index

| File | Contents |
|------|----------|
| `QUICKSTART.md` | Fast setup from scratch |
| `IMPLEMENTATION.md` | This file — architecture and file connections |
| `docs/FONTS.md` | Font setup, configuration, and troubleshooting |
| `docs/SPRITES_AND_ICONS.md` | Sprite setup and icon usage |
| `docs/ICON_REFERENCE.md` | Full icon name reference |
| `docs/REACT_NATIVE_SETUP.md` | MapLibre React Native integration |

---

## Known Issues and Fixes Applied

| Issue | Cause | Fix |
|-------|-------|-----|
| `bash` commands fail on Windows | No WSL distro installed | Use `.ps1` scripts instead |
| `npm install -g tileserver-gl` fails in Docker | `canvas` native module needs Python/build tools | Use `maptiler/tileserver-gl` Docker image directly |
| Sprites 404 | Original URLs pointed to `osm-bright.*` files | Files are named `osm-liberty.*` on the gh-pages branch |
| Font glyphs 404 | Style used `/data/glyphs/` path | Correct path is `/fonts/` |
| Planetiler fails on missing sources | OpenMapTiles profile needs extra geo datasets | Add `--download` flag to Planetiler command |
| Style validation warning | `center` had 3 values `[lon, lat, zoom]` | Fixed to 2 values `[lon, lat]`; zoom is separate |
| `tileserver-gl-config.json` wrong structure | `styles`/`data` nested under `options` | Moved to top-level keys with correct `paths` config |

---

## External Resources

- [Planetiler](https://github.com/onthegomap/planetiler)
- [TileServer GL](https://github.com/maptiler/tileserver-gl)
- [maptiler/tileserver-gl Docker](https://hub.docker.com/r/maptiler/tileserver-gl)
- [MapLibre GL JS](https://maplibre.org/maplibre-gl-js/docs/)
- [MapLibre React Native](https://maplibre.org/maplibre-react-native/)
- [OpenMapTiles Schema](https://openmaptiles.org/schema/)
- [Geofabrik Algeria](https://download.geofabrik.de/africa/algeria.html)
- [OSM Liberty Style](https://github.com/openmaptiles/osm-liberty-gl-style)
- [OpenMapTiles Fonts](https://github.com/openmaptiles/fonts)
