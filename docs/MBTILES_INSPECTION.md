# MBTiles Inspection Guide

How to verify, inspect, and debug your `.mbtiles` files using the scripts in this project.

---

## Quick Start

```powershell
# HTML dashboard — opens in browser with charts (recommended)
npm run verify:tiles:dashboard

# Terminal visual dashboard with bar charts
npm run verify:tiles:visual

# Plain pass/fail output (good for scripting/CI)
npm run verify:tiles
```

Both scripts check `data/algeria.mbtiles` and `data/overture-algeria.mbtiles`.

---

## Prerequisites

**sqlite3** must be on your PATH. On this machine it ships with the Android SDK:

```
C:\Users\<you>\AppData\Local\Android\Sdk\platform-tools\sqlite3.exe
```

If it's not found, install it:

```powershell
choco install sqlite
```

Verify it works:

```powershell
sqlite3 --version
```

---

## Scripts

### `scripts/verify-mbtiles-dashboard.ps1`

Generates `mbtiles-dashboard.html` and opens it in your browser. Includes:
- Summary cards (tile counts and file sizes for both files)
- Interactive bar charts (zoom distribution per file, powered by Chart.js)
- Metadata tables (bounds, format, zoom range, attribution)
- Color-coded integrity status

```powershell
npm run verify:tiles:dashboard
# or directly:
powershell -ExecutionPolicy Bypass -File scripts/verify-mbtiles-dashboard.ps1
```

The output file is written to `mbtiles-dashboard.html` at the project root and opens automatically.

---

### `scripts/verify-mbtiles-visual.ps1`

Visual dashboard with bar charts and clean layout. Use this for day-to-day inspection.

```powershell
npm run verify:tiles:visual
# or directly:
powershell -ExecutionPolicy Bypass -File scripts/verify-mbtiles-visual.ps1
```

**Sample output:**

```
######################################
#   MBTiles Verification Dashboard   #
######################################
  Project: C:\ProjectsRepo\planetiler-config-repo

-------------------------
  OSM (algeria.mbtiles)
-------------------------
  Size   : 285.8 MB
  PASS   Integrity check
  Tiles  : 223000+
  Zooms  : 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14

  Metadata:
    bounds           -9.5,18.5,9.5,37.5
    center           5.5,27.5,5
    format           pbf
    maxzoom          14
    minzoom          0
    name             OpenMapTiles

  Zoom Distribution:
    z 0  [                              ]  1
    z12  [###                           ]  11900
    z13  [#########                     ]  37521
    z14  [##############################]  118905

  Top 5 Largest Tiles:
    z14 x8330 y9993  ->  149.9 KB
    ...

---------------------------------------
  Overture (overture-algeria.mbtiles)
---------------------------------------
  Size   : 5.07 MB
  PASS   Integrity check
  Tiles  : 8332
  Zooms  : 12,13,14
  ...

  All checks passed.
```

---

### `scripts/diagnose-coverage.ps1`

Checks whether tiles exist for key geographic locations across Algeria. Use this after regenerating tiles to confirm full coverage, especially for the west (Oran, Tlemcen, Tindouf) and south (Tamanrasset, In Salah).

```powershell
powershell -ExecutionPolicy Bypass -File scripts/diagnose-coverage.ps1
```

**Sample output (all regions covered):**
```
=== Algeria MBTiles Coverage Diagnostic ===
Stored bounds: -9.5,18.5,9.5,37.5

Checking tiles at zoom 8...

  FOUND   Algiers (center)    (3.06, 36.74)
  FOUND   Oran (west)         (-0.63, 35.69)
  FOUND   Tlemcen (NW)        (-1.31, 34.88)
  FOUND   Tindouf (far west)  (-8.1, 27.67)
  FOUND   Tamanrasset (S)     (5.52, 22.78)
  FOUND   In Salah (S)        (2.47, 27.2)
  FOUND   Annaba (east)       (7.76, 36.9)
  FOUND   Constantine (NE)    (6.61, 36.37)
```

If any location shows `MISSING`, the bounds used during tile generation were too narrow. See the Troubleshooting guide.

---

### `scripts/verify-mbtiles.ps1`

Plain text output — easier to parse in logs or CI pipelines.

```powershell
npm run verify:tiles
# or directly:
powershell -ExecutionPolicy Bypass -File scripts/verify-mbtiles.ps1
```

Exits with code `1` if any check fails, `0` on success.

---

## What Gets Checked

| Check | What it means |
|-------|--------------|
| File exists + size | Basic sanity — confirm Planetiler/tippecanoe wrote the file |
| `PRAGMA integrity_check` | SQLite-level corruption detection |
| Tile count | Confirm tiles were actually written (empty = regenerate) |
| Zoom levels present | Verify your expected zoom range (z12-14 for Overture, z0-14 for OSM) |
| Metadata | Bounds, attribution, format, zoom range |
| Zoom distribution | See which zoom levels have the most data |
| Top 5 largest tiles | Identify dense areas that may slow rendering |

---

## Manual SQLite Queries

If you need to go deeper, run queries directly. sqlite3 treats `|` as a column separator.

**Count tiles:**
```powershell
sqlite3 data\algeria.mbtiles "SELECT COUNT(*) FROM tiles;"
```

**Tiles per zoom level:**
```powershell
sqlite3 data\algeria.mbtiles "SELECT zoom_level, COUNT(*) FROM tiles GROUP BY zoom_level ORDER BY zoom_level;"
```

**View metadata:**
```powershell
sqlite3 data\algeria.mbtiles "SELECT name, value FROM metadata ORDER BY name;"
```

**Check bounds:**
```powershell
sqlite3 data\algeria.mbtiles "SELECT value FROM metadata WHERE name='bounds';"
# Expected: -9.5,18.5,9.5,37.5  (full Algeria including Oran and Tindouf)
```

**Find largest tiles (debug performance):**
```powershell
sqlite3 data\algeria.mbtiles "SELECT zoom_level, tile_column, tile_row, LENGTH(tile_data) FROM tiles ORDER BY LENGTH(tile_data) DESC LIMIT 10;"
```

**File corruption check:**
```powershell
sqlite3 data\algeria.mbtiles "PRAGMA integrity_check;"
# Expected: ok
```

**Total compressed size of all tile data:**
```powershell
sqlite3 data\algeria.mbtiles "SELECT printf('%.2f MB', SUM(LENGTH(tile_data)) / 1024.0 / 1024.0) FROM tiles;"
```

---

## Expected Values

### `algeria.mbtiles` (OSM)

| Property | Expected |
|----------|----------|
| File size | ~286 MB |
| Tile count | ~220,000+ |
| Zoom levels | 0 – 14 |
| Format | pbf (gzip compressed) |
| Bounds | `-9.5,18.5,9.5,37.5` |
| Largest tile | ~150 KB |

### `overture-algeria.mbtiles` (Overture POIs)

| Property | Expected |
|----------|----------|
| File size | ~5 MB |
| Tile count | ~8,300 |
| Zoom levels | 12 – 14 |
| Format | pbf |
| Layer | `place` (43,390 POI features) |
| Subclasses | 72 (restaurant, mosque, bank, hotel, …) |

---

## Recommended Workflow After Regenerating Tiles

Run this after each Planetiler or tippecanoe run to confirm the output is valid:

```powershell
# 1. Visual check
npm run verify:tiles:visual

# 2. If all good, restart TileServer
docker compose restart tileserver

# 3. Confirm it's serving
npm run health
```

---

## Troubleshooting

### Tile count is 0
Planetiler/tippecanoe did not write any tiles. Re-run tile generation:
```powershell
npm run process-tiles   # OSM
# or re-run tippecanoe for Overture
```

### Integrity check fails
The file is corrupted — regenerate it. Do not use a corrupted MBTiles file in production.

### Zoom levels missing
Check your Planetiler config (`planetiler-config.json`) or tippecanoe `--minimum-zoom` / `--maximum-zoom` flags.

### sqlite3 not found
See Prerequisites above. The Android SDK ships sqlite3 — if Android tools are on your PATH you already have it.

---

## Visual Inspection with DB Browser for SQLite

A GUI alternative to the CLI scripts. Good for ad-hoc exploration when you want to click through data instead of writing queries.

### Installation

1. Download from [sqlitebrowser.org/dl](https://sqlitebrowser.org/dl/) — grab the **win64 .msi** file
2. Run the installer (takes ~2 minutes, no configuration needed)
3. Find it in the Start menu as **"DB Browser for SQLite"**

### Opening an MBTiles File

MBTiles files are standard SQLite databases, but DB Browser hides them by default because of the `.mbtiles` extension. To open one:

1. **File → Open Database**
2. Navigate to `C:\ProjectsRepo\planetiler-config-repo\data\`
3. Click the **file type dropdown** at the bottom of the dialog (shows "SQLite Database Files")
4. Switch it to **All files (*.*)**
5. Select your file (`algeria.mbtiles`, `overture-algeria.mbtiles`, or `custom-algeria.mbtiles`) and click **Open**

### Interface Overview

| Tab | Use |
|-----|-----|
| **Database Structure** | See the table list (`tiles`, `metadata`) |
| **Browse Data** | Select a table and scroll through rows visually |
| **Execute SQL** | Paste and run queries — press **F5** to execute |

### Step-by-Step: Checking a File

1. Open the file (see above)
2. **Browse Data** → **metadata** table → read zoom levels, bounds, attribution
3. **Browse Data** → **tiles** table → row count at the bottom = total tiles
4. **Execute SQL** tab → paste any query from the Manual SQLite Queries section above → press **F5**

### Editing Metadata

1. **Browse Data** → **metadata** table
2. Click on a value cell to edit it inline
3. Press **Enter** to confirm the cell
4. Click the **Write Changes** button (floppy disk icon in the toolbar) to save to disk

This is useful for fixing the `name`, `attribution`, or `description` metadata fields after generation.

### What You Cannot Do in DB Browser

The `tile_data` column contains gzip-compressed binary PBF data — not human-readable. You cannot view or edit the actual map features (POIs, roads, etc.) through DB Browser. To change POI data, edit the source GeoJSON and re-tile. See [POI_MANAGEMENT.md](./POI_MANAGEMENT.md).
