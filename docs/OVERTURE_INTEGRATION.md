# Overture Maps Integration

Adds 40,000+ commercial POIs (restaurants, shops, clinics, schools, etc.) from Overture Maps to the existing OSM tile server, served as a separate vector tile source alongside the OSM MBTiles.

## Architecture

```
algeria.mbtiles          ← OSM data via Planetiler (untouched)
overture-algeria.mbtiles ← Overture data via tippecanoe (new)
```

Both are served by the same TileServer GL instance. The MapLibre style references them as two independent sources (`openmaptiles` and `overture`).

---

## Prerequisites

- Docker (already running TileServer GL)
- No other local tools required — Python and tippecanoe run inside Docker containers

---

## Step 1 — Download Overture Places

Uses the official `overturemaps` Python CLI inside a Docker container. Downloads all place features within the Algeria bounding box directly from Overture's AWS S3 bucket (no credentials needed).

```powershell
New-Item -ItemType Directory -Force ".\data\overture"

docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data/overture:/data" `
  python:3.11-slim `
  sh -c "pip install -q overturemaps && overturemaps download --bbox='2.0,18.0,9.0,37.0' --type=place -f geojson -o /data/algeria-overture.geojson"
```

**Output:** `data/overture/algeria-overture.geojson` (~91 MB, 81,673 features)

---

## Step 2 — Flatten and Filter

Overture uses its own category schema (793 distinct values). This script:
- Maps Overture categories to OMT-compatible `subclass` values
- Removes geographic features (rivers, mountains, etc.)
- Removes low-confidence entries (< 0.3)
- Flattens nested properties to a flat `name` + `subclass` + `confidence` structure

```powershell
docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data/overture:/data" `
  -v "c:/ProjectsRepo/planetiler-config-repo/scripts:/scripts" `
  python:3.11-slim `
  python /scripts/flatten-overture.py /data/algeria-overture.geojson /data/algeria-overture-flat.geojson
```

**Script:** `scripts/flatten-overture.py`

**Output:** `data/overture/algeria-overture-flat.geojson` (~9 MB, 40,870 features)

Results after filtering:

| Kept | Skipped (geographic) | Skipped (low confidence) | Skipped (unmapped) |
|---|---|---|---|
| 40,870 | 25,568 | 10,256 | 4,979 |

Top subclasses in output:

| subclass | count |
|---|---|
| shop | 8,660 |
| school | 4,609 |
| clothes | 4,235 |
| restaurant | 3,146 |
| doctors | 2,212 |
| hairdresser | 1,530 |
| dentist | 1,274 |
| furniture | 1,150 |
| hotel | 1,142 |
| attraction | 1,124 |
| college | 1,094 |
| hospital | 876 |
| pharmacy | 838 |
| sports_centre | 795 |
| cafe | 782 |

---

## Step 3 — Convert to MBTiles

Uses `tippecanoe` (via Docker) to convert the filtered GeoJSON to a vector tile MBTiles file at zoom levels 12–14.

```powershell
# Pull the tippecanoe image (one-time)
docker pull klokantech/tippecanoe

docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" `
  klokantech/tippecanoe `
  tippecanoe `
    -o /data/overture-algeria.mbtiles `
    --layer=place `
    --minimum-zoom=12 `
    --maximum-zoom=14 `
    --drop-densest-as-needed `
    --extend-zooms-if-still-dropping `
    --force `
    /data/overture/algeria-overture-flat.geojson
```

**Output:** `data/overture-algeria.mbtiles` (4.9 MB)

---

## Step 4 — Register with TileServer GL

Add the Overture MBTiles as a second data source in `tileserver-gl-config.json`:

```json
{
  "data": {
    "algeria": {
      "mbtiles": "algeria.mbtiles"
    },
    "overture": {
      "mbtiles": "overture-algeria.mbtiles"
    }
  }
}
```

---

## Step 5 — Add Source to Style

In `osm-liberty-style.json`, add the `overture` source alongside the existing `openmaptiles` source:

```json
{
  "sources": {
    "openmaptiles": {
      "type": "vector",
      "url": "mbtiles://algeria"
    },
    "overture": {
      "type": "vector",
      "url": "mbtiles://overture"
    }
  }
}
```

---

## Step 6 — Add Style Layers

37 `ov_*` layers were added to `osm-liberty-style.json` after the `poi_general_z14` layer. Each targets `"source": "overture"` and `"source-layer": "place"`.

Structure of each layer:

```json
{
  "id": "ov_hospital",
  "type": "symbol",
  "source": "overture",
  "source-layer": "place",
  "minzoom": 12,
  "filter": ["==", "subclass", "hospital"],
  "layout": {
    "icon-image": "hospital_11",
    "icon-size": 1,
    "text-field": ["get", "name"],
    "text-font": ["Open Sans Regular", "Arial Unicode MS Regular"],
    "text-size": 10,
    "text-anchor": "top",
    "text-offset": [0, 0.9],
    "text-optional": true,
    "text-max-width": 8
  },
  "paint": {
    "text-color": "#b30000",
    "text-halo-color": "#fff",
    "text-halo-width": 1
  }
}
```

Full layer list by zoom:

**Zoom 12 (city scale):** `ov_hospital`, `ov_fire_station`

**Zoom 13 (neighbourhood):** `ov_pharmacy`, `ov_doctor`, `ov_dentist`, `ov_veterinary`, `ov_school`, `ov_college`, `ov_library`, `ov_mosque`, `ov_worship`, `ov_hotel`, `ov_bank`, `ov_fuel`, `ov_police`, `ov_prison`, `ov_town_hall`, `ov_post`, `ov_embassy`

**Zoom 14 (street):** `ov_restaurant`, `ov_cafe`, `ov_fast_food`, `ov_bakery`, `ov_bar`, `ov_grocery`, `ov_shop`, `ov_clothing`, `ov_hairdresser`, `ov_parking`, `ov_museum`, `ov_cinema`, `ov_theatre`, `ov_stadium`, `ov_attraction`, `ov_butcher`, `ov_florist`, `ov_laundry`

---

## Step 7 — Restart TileServer

```powershell
docker compose restart tileserver
```

Verify at: http://localhost:8080/styles/osm-liberty/

---

## Refreshing Overture Data

Overture releases new data approximately every 2 months. To update:

```powershell
# Re-download (latest release is fetched automatically)
docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data/overture:/data" `
  python:3.11-slim `
  sh -c "pip install -q overturemaps && overturemaps download --bbox='2.0,18.0,9.0,37.0' --type=place -f geojson -o /data/algeria-overture.geojson"

# Re-flatten
docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data/overture:/data" `
  -v "c:/ProjectsRepo/planetiler-config-repo/scripts:/scripts" `
  python:3.11-slim `
  python /scripts/flatten-overture.py /data/algeria-overture.geojson /data/algeria-overture-flat.geojson

# Re-tile
docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" `
  klokantech/tippecanoe `
  tippecanoe -o /data/overture-algeria.mbtiles --layer=place `
    --minimum-zoom=12 --maximum-zoom=14 `
    --drop-densest-as-needed --force `
    /data/overture/algeria-overture-flat.geojson

# Restart
docker compose restart tileserver
```

---

## Data Sources

| File | Size | Description |
|---|---|---|
| `data/overture/algeria-overture.geojson` | 91 MB | Raw download from Overture S3 |
| `data/overture/algeria-overture-flat.geojson` | 9 MB | Filtered and flattened |
| `data/overture-algeria.mbtiles` | 4.9 MB | Final vector tiles |

These files are excluded from git (see `.gitignore`).

---

## Verification Commands

```powershell
# Check MBTiles metadata
docker run --rm -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" alpine `
  sh -c "apk add -q sqlite && sqlite3 /data/overture-algeria.mbtiles 'SELECT name, value FROM metadata;'"

# Count tiles by zoom
docker run --rm -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" alpine `
  sh -c "apk add -q sqlite && sqlite3 /data/overture-algeria.mbtiles 'SELECT zoom_level, COUNT(*) FROM tiles GROUP BY zoom_level;'"

# Confirm style JSON is valid
Get-Content "osm-liberty-style.json" -Raw | ConvertFrom-Json | Select-Object -ExpandProperty layers | Where-Object { $_.id -like "ov_*" } | Measure-Object
# Expected: Count = 37

# Check TileServer is serving both sources
Invoke-WebRequest "http://localhost:8080/data/overture.json" | Select-Object StatusCode
# Expected: 200
```