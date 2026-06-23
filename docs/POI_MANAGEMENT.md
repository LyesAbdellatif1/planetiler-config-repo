# POI Management Guide

How to add, update, and manage custom Points of Interest in the Algeria transport app map.

---

## Architecture

The map has four independent POI layers:

| Layer | Source file | MBTiles | Who edits it |
|-------|-------------|---------|--------------|
| OSM | `algeria-latest.osm.pbf` | `algeria.mbtiles` | OpenStreetMap community — read-only |
| Overture | `data/overture/algeria-overture-flat.geojson` | `overture-algeria.mbtiles` | Re-downloaded from Overture Maps |
| **Custom** | `data/custom-pois.geojson` | `custom-algeria.mbtiles` | **You — add anything here** |
| **Transit** | `data/transit-stations.geojson` | `transit-algeria.mbtiles` | **Auto-generated from OSM — don't hand-edit** |

Custom POIs are styled with `cu_*` layers in `osm-liberty-style.json` and rendered slightly larger than Overture POIs (icon-size 1.1 vs 1.0) so they're visually distinguishable.

---

## Quick Start

### Try it immediately with the example file

An example CSV with 50 real Algerian POIs is included at `data/example-pois.csv`. Run it to test the full pipeline:

```powershell
npm run import:pois -- --csv data/example-pois.csv
npm run retile:custom
```

Then open `http://localhost:8080` — you should see bus stations, hospitals, mosques, hotels and more across Algiers, Oran and Constantine.

### Add a single POI interactively

```powershell
npm run add:poi
```

Prompts you for name, lat/lon, and subclass, then optionally re-tiles.

### Bulk-import from CSV

Place the CSV file inside the project directory (e.g. `data/my-bus-stops.csv`), then:

```powershell
npm run import:pois -- --csv data/my-bus-stops.csv
```

Then publish to the map:

```powershell
npm run retile:custom
```

---

## CSV Format

The import script accepts any CSV with these columns (header row required):

```
name,lat,lon,subclass[,confidence,notes]
```

| Column | Required | Description |
|--------|----------|-------------|
| `name` | Yes | Display name shown on the map |
| `lat` | Yes | Latitude (decimal degrees, e.g. `36.7538`) |
| `lon` | Yes | Longitude (decimal degrees, e.g. `3.0588`) |
| `subclass` | Yes | OMT category (see table below) |
| `confidence` | No | Data quality score 0–1 (default: `1.0`) |
| `notes` | No | Free-text note, stored in GeoJSON but not rendered |

### Example CSV

A ready-to-use example is included at `data/example-pois.csv` — 50 real Algerian locations covering all transport-priority subclasses across Algiers, Oran and Constantine. Use it as a template for your own data.

Minimal example:
```csv
name,lat,lon,subclass,confidence,notes
Gare Routière Caroubier,36.7367,3.0869,bus_station,1.0,Main intercity bus terminal
Aéroport Houari Boumédiène,36.6960,3.2152,aerodrome,1.0,International airport
CHU Mustapha Pacha,36.7444,3.0650,hospital,1.0,Public hospital
Station Total El Harrach,36.7220,3.1030,fuel,1.0,
```

---

## Supported Subclasses

### Transport (Priority 1 — add first)

| Subclass | Description |
|----------|-------------|
| `bus_station` | Bus terminals and stops |
| `station` | Train/railway stations |
| `subway` | Metro stations |
| `aerodrome` | Airports |
| `ferry_terminal` | Ferry ports |
| `parking` | Parking lots/garages |
| `fuel` | Petrol/gas stations |
| `car_rental` | Car hire agencies |

### Safety & Navigation (Priority 2)

| Subclass | Description |
|----------|-------------|
| `hospital` | Hospitals and clinics |
| `police` | Police stations |
| `fire_station` | Fire stations |
| `pharmacy` | Pharmacies |
| `post_office` | Post offices |
| `town_hall` | Municipal offices |
| `embassy` | Embassies/consulates |

### Services (Priority 3)

| Subclass | Description |
|----------|-------------|
| `bank` | Banks |
| `atm` | ATMs |
| `hotel` | Hotels and motels |
| `hostel` | Hostels |
| `car_repair` | Auto repair shops |

### Full Subclass List

```
aerodrome, amusement_ride, aquarium, atm, attraction,
bakery, bank, bar, bicycle, bus_station, butcher,
cafe, camp_site, car_rental, car_repair, castle,
church, cinema, clothes, college, convenience,
dentist, doctors, embassy,
fast_food, ferry_terminal, fire_station, florist, fuel, furniture,
gallery, garden, golf_course, grocery,
hairdresser, hospital, hostel, hotel,
ice_cream, jewelry, kindergarten,
laundry, library, lighthouse,
marina, monument, mosque, museum,
office, park, parking, pharmacy, pitch, place_of_worship,
playground, police, post_office, prison,
restaurant, school, shoes, shop, sports_centre, stadium,
station, subway, supermarket, swimming, synagogue,
theatre, town_hall, veterinary, zoo
```

---

## Full Workflow

### Step-by-step: Bulk import

```powershell
# 1. Prepare your CSV and place it inside the project (e.g. data/my-pois.csv)
# 2. Import (runs via Docker — Docker must be running)
npm run import:pois -- --csv data/my-pois.csv

# 3. Check the result
cat data/custom-pois.geojson | python -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d[\"features\"])} POIs')"

# 4. Re-tile (runs tippecanoe + restarts TileServer)
npm run retile:custom

# 5. Verify
npm run verify:tiles:visual

# 6. Check the map
# Open http://localhost:8080
```

### Import + retile in one command

```powershell
npm run import:pois -- --csv my-pois.csv --retile
```

---

## Visual Database Editing (DB Browser for SQLite)

### Installation

1. Download the Windows installer from [sqlitebrowser.org/dl](https://sqlitebrowser.org/dl/)
   - File: **DB.Browser.for.SQLite-v3.13.1-win64.msi** (or latest)
2. Run the `.msi` — click through the wizard, takes ~2 minutes
3. Launch from Start menu: search **"DB Browser for SQLite"**

### Opening an MBTiles File

MBTiles files have a `.mbtiles` extension which DB Browser hides by default. To open one:

1. Click **File → Open Database**
2. Navigate to `C:\ProjectsRepo\planetiler-config-repo\data\`
3. At the bottom of the dialog, click the **file type dropdown** (shows "SQLite Database Files (*.db ...)")
4. Change it to **All files (*.*)**
5. Your `.mbtiles` files appear — select one and click **Open**

Files you can open:
- `algeria.mbtiles` — OSM base map (~286 MB, full Algeria)
- `overture-algeria.mbtiles` — Overture POIs (5 MB)
- `custom-algeria.mbtiles` — your custom POIs

### Navigating the Interface

Once a file is open you'll see four tabs:

| Tab | What it does |
|-----|-------------|
| **Database Structure** | Shows tables: `tiles`, `metadata`, (sometimes `images`) |
| **Browse Data** | Click a table name to view its rows visually |
| **Execute SQL** | Type and run SQL queries manually |
| **Edit Pragmas** | SQLite settings (rarely needed) |

### Inspecting the Data

**Step 1 — Check metadata** (zoom levels, bounds, attribution):
- Click **Browse Data** tab → select **metadata** table
- You'll see key-value rows like `minzoom: 12`, `bounds: -9.5,18.5,9.5,37.5`, `format: pbf`

**Step 2 — Check tile counts**:
- Click **Browse Data** tab → select **tiles** table
- The row count shown at the bottom is your total tile count

**Step 3 — Run a query** (Execute SQL tab):
- Click **Execute SQL** tab
- Paste a query and press **F5** or click the **Play** button

### Useful SQL Queries

Copy-paste these into the **Execute SQL** tab:

```sql
-- Total tile count
SELECT COUNT(*) AS total_tiles FROM tiles;

-- Tiles per zoom level (distribution)
SELECT zoom_level, COUNT(*) AS tiles
FROM tiles
GROUP BY zoom_level
ORDER BY zoom_level;

-- File metadata (bounds, zoom range, format, attribution)
SELECT name, value FROM metadata ORDER BY name;

-- Check integrity (should return "ok")
PRAGMA integrity_check;

-- Total size of tile data
SELECT printf('%.2f MB', SUM(LENGTH(tile_data)) / 1024.0 / 1024.0) AS size
FROM tiles;

-- Largest 10 tiles (useful for finding dense areas)
SELECT zoom_level, tile_column, tile_row,
       CAST(LENGTH(tile_data) / 1024 AS INT) || ' KB' AS size
FROM tiles
ORDER BY LENGTH(tile_data) DESC
LIMIT 10;

-- Bounds check
SELECT value FROM metadata WHERE name = 'bounds';
```

### Editing Metadata

You can directly edit metadata values (e.g. fix the attribution or description):

1. **Browse Data** tab → select **metadata** table
2. Click on any cell in the `value` column
3. Edit the text inline
4. Click **Apply** (or press Enter)
5. Click **Write Changes** (top toolbar, floppy disk icon) to save

### Important Limitation

**You cannot edit POI data inside DB Browser.** MBTiles tile blobs (`tile_data` column) are gzip-compressed binary PBF format — not readable or editable as text. To add or change POIs:

1. Edit `data/custom-pois.geojson` (or use `npm run import:pois`)
2. Re-tile: `npm run retile:custom`
3. The new MBTiles file can then be inspected in DB Browser

DB Browser is useful for **reading** state and **editing metadata** — not for editing POI content.

---

## Rollback

The import script backs up `custom-pois.geojson` before writing:
```
data/custom-pois.geojson.bak-YYYYMMDD-HHmmss
```

The retile script backs up `custom-algeria.mbtiles`:
```
data/custom-algeria.mbtiles.bak-YYYYMMDD-HHmm
```

To rollback:
```powershell
# Restore GeoJSON
copy data\custom-pois.geojson.bak-20260621-143022 data\custom-pois.geojson

# Re-tile from restored GeoJSON
npm run retile:custom
```

---

## Style Layers

Custom POIs are rendered by `cu_*` layers in `osm-liberty-style.json`, all using `source: "custom"` and `source-layer: "place"`.

| Layer | Zoom | Subclasses |
|-------|------|-----------|
| `cu_bus_station` | 12 | bus_station |
| `cu_station` | 12 | station |
| `cu_aerodrome` | 12 | aerodrome |
| `cu_hospital` | 12 | hospital |
| `cu_fire_station` | 12 | fire_station |
| `cu_pharmacy` | 13 | pharmacy |
| `cu_police` | 13 | police |
| `cu_fuel` | 13 | fuel |
| `cu_parking` | 13 | parking |
| `cu_car_rental` | 13 | car_rental |
| `cu_hotel` | 13 | hotel, hostel |
| `cu_school` | 13 | school, kindergarten |
| `cu_bank` | 13 | bank, atm |
| `cu_mosque` | 13 | mosque |
| `cu_restaurant` | 14 | restaurant |
| `cu_poi` | 14 | everything else |

Custom POIs appear slightly larger (icon-size 1.1) than Overture POIs (1.0) and with a thicker text halo so they stand out as operator-verified data.

---

## npm Scripts

| Command | Description |
|---------|-------------|
| `npm run add:poi` | Interactive: add a single POI, optionally retile |
| `npm run import:pois -- --csv file.csv` | Bulk import from CSV |
| `npm run import:pois -- --csv file.csv --retile` | Import and immediately retile |
| `npm run retile:custom` | Re-tile custom GeoJSON and restart TileServer |
| `npm run fetch:transit` | Pull Algeria metro/tram stations from OSM into `data/transit-stations.geojson` |
| `npm run retile:transit` | Re-tile transit stations and restart TileServer |
| `npm run verify:tiles:visual` | Check all MBTiles files including custom |

---

## Transit Stations (OSM-sourced)

The base `algeria.mbtiles` was built from an OSM snapshot in which many **metro (subway) and tram** stations had no `name` tag, so they rendered with only a generic "Station métro" / "Arrêt de tram" fallback. The real names (and exact coordinates) *do* exist in current OpenStreetMap, so we pull them on demand into a dedicated `transit` source instead of re-tiling the whole country.

**Pipeline** (separate from the hand-curated `custom` source so the two never collide):

```
Overpass API ──fetch:transit──▶ data/transit-stations.geojson ──retile:transit──▶ data/transit-algeria.mbtiles
                                                                                          │
                                          tileserver-gl-config.json  ("transit" source)
                                                                                          ▼
                                          osm-liberty-style.json: layers tr_metro, tr_tram
```

- `scripts/fetch-transit-stations.py` queries Overpass for every Algeria `railway=tram_stop`, `station=subway`, `amenity=bus_station`, `highway=bus_stop` and `aerialway=station` (téléphérique / cable car) node — plus aerialway station **ways** (via `out center`). All cities: Algiers metro + Algiers/Oran/Constantine/Sidi Bel Abbès/Ouargla/Sétif/Mostaganem trams, bus terminals and stops nationwide, and téléphériques (Algiers, Blida, Chréa, Oran, Tlemcen, Annaba, Constantine, Tizi Ouzou…). Each becomes a GeoJSON point with `mode` (`metro` / `tram` / `bus_station` / `bus` / `aerialway`), `name`, `name_fr`, `name_ar`. Output: `data/transit-stations.geojson`.
- The same script **also fetches the route LINE geometry** (`railway=subway|tram|light_rail` track ways + `aerialway` cables, via `out geom`) into `data/transit-lines.geojson` with `mode` `metro` / `tram` / `aerialway`. This is needed because the base OpenMapTiles tiles don't emit tram lines at all and only carry subway/aerialway lines from ~z14. The `tr_*` station points and the `trl_*` route lines are tiled together by `retile-transit.ps1` into one `transit-algeria.mbtiles` with **two layers**: `transit` (points) and `transitlines` (lines).
- The `trl_metro` / `trl_tram` / `trl_aerialway` line layers (source-layer `transitlines`) **replace** the base `transit_subway` / `transit_tram` / `transit_aerialway` line layers and render from **z11**, so the coloured metro/tram/téléphérique lines appear together with the station icons. (`transit_railway` mainline and `transit_light_rail` base layers are kept.)
- The `tr_metro` / `tr_tram` / `tr_bus_station` / `tr_bus_stop` / `tr_aerialway` style layers **replace** the old base `poi_metro_station` / `poi_tram_stop` / `poi_bus_station` / `poi_bus_stop` / `poi_aerialway_station` layers, so there are no duplicate icons. Labels coalesce **Latin-first**: `name_fr` → `name` → `name_ar` → generic fallback (prefers readable French/Latin, falls back to Arabic, then a generic label).
- Metro, tram & aerialway labels are forced (`text-allow-overlap`) so every station icon always carries a name. Bus stations and bus stops use collision binding (icon + label drop together) so dense areas declutter and you never get a naked icon.
- **Labels prefer Latin (`name_fr` → `name` → `name_ar` → fallback).** Many stations are named only in Arabic, so an **Arabic font is required** or those labels render blank. The bundled Open Sans has no Arabic glyphs, so `data/fonts/Noto Sans Arabic` is generated by `npm run fonts:arabic` (downloads Noto Sans Arabic + converts to glyph PBFs via `scripts/_genfont.cjs`) and added to the transit layers' font stacks (`["Open Sans Bold", "Noto Sans Arabic", "Arial Unicode MS Bold"]`). Re-run only if you change the Arabic font; then `docker compose restart tileserver`.
- **`tr_bus_stop` only renders bus stops that have a name in OSM.** There are thousands of bus stops in Algeria and roughly a third have no name tag at all — those are omitted rather than flooding the map with generic "Arrêt de bus" markers. To see/name them, add the name in OpenStreetMap (next `fetch:transit` picks it up) or add the stop via the `custom` pipeline.

**Approximate coverage** (regenerated each fetch, so counts drift as OSM grows): ~40 metro, ~356 tram, ~450 bus stations, ~4170 bus stops (~2700 of them named), ~82 aerialway (téléphérique) stations (~78 named). Anything still showing a generic fallback ("Arrêt de bus", "Gare routière", "Station métro", "Arrêt de tram") genuinely has no name in OpenStreetMap — that is a data gap in OSM, not a styling bug, and the only fix is to map the name upstream or add it via `custom`.

**To refresh** (e.g. after new stations open in OSM):

```powershell
npm run fetch:transit     # re-pulls from OSM, overwrites transit-stations.geojson (keeps a .bak)
npm run retile:transit    # rebuilds transit-algeria.mbtiles and restarts TileServer
```

Do **not** hand-edit `data/transit-stations.geojson` — it is regenerated wholesale on each fetch. To correct or add a station, fix it in OpenStreetMap (it'll appear on the next `fetch:transit`), or add it as a one-off via the `custom` pipeline above.

---

## Validation Rules

The import script enforces:
- `name` is non-empty
- `lat` is a valid number between 17–38
- `lon` is a valid number between -2–12
- `subclass` is in the known OMT subclass list
- `confidence` is between 0–1 (default 1.0)
- No exact duplicate: same name + coordinates (5 decimal places) are skipped

Invalid rows are reported but don't stop the import — valid rows still get added.
