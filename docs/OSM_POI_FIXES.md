# OSM POI Style Fixes

Documents corrections to `osm-liberty-style.json` POI layer filters discovered through a mbtiles audit. These fixes unlocked ~561 previously invisible POIs from the existing `algeria.mbtiles` without any data rebuild.

---

## Background

Planetiler extracts all OSM POIs into the `poi` layer using the OpenMapTiles (OMT) schema. Each feature has a `class` (broad category) and `subclass` (specific type). The original style filters used incorrect or incomplete subclass values, hiding large numbers of POIs.

### How the audit was done

```powershell
docker run --rm `
  -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" `
  -v "c:/ProjectsRepo/planetiler-config-repo/scripts:/scripts" `
  python:3.11-slim `
  sh -c "pip install -q mapbox-vector-tile && python /scripts/audit-osm-poi.py /data/algeria.mbtiles"
```

This samples 20 zoom-14 tiles across Algeria's populated areas and decodes the `poi` layer to inventory all `class`/`subclass` values present in the data.

---

## Fixes Applied

### Fix 1 — Mosque filter used wrong subclass value (CRITICAL)

**Hidden POIs: ~106**

The OMT schema stores mosques with `subclass: muslim`, **not** `subclass: mosque`. The original filter matched nothing.

```json
// Before (matched 0 features)
"filter": ["==", "subclass", "mosque"]

// After (matches all mosques)
"filter": ["==", "subclass", "muslim"]
```

The companion `poi_worship` layer exclusion was also corrected:

```json
// Before
["!=", "subclass", "mosque"]

// After
["!=", "subclass", "muslim"]
```

---

### Fix 2 — Town hall filter missed 4 variants

**Hidden POIs: ~260**

The OMT schema uses multiple subclasses for government/civic buildings. The original filter only matched `town_hall`.

| Subclass | Count | Description |
|---|---|---|
| `government` | 192 | Government offices (class: `office`) |
| `community_centre` | 32 | Community centers |
| `townhall` | 24 | Alternative spelling without underscore |
| `courthouse` | 12 | Courthouses |
| `public_building` | 5 | Generic public buildings |

```json
// Before
"filter": ["==", "subclass", "town_hall"]

// After
"filter": ["in", "subclass", "town_hall", "townhall", "government", "community_centre", "courthouse", "public_building"]
```

---

### Fix 3 — Embassy filter used wrong subclass value

**Hidden POIs: ~12**

The OMT schema stores embassies with `subclass: diplomatic`.

```json
// Before (matched 0 embassies)
"filter": ["==", "subclass", "embassy"]

// After
"filter": ["in", "subclass", "embassy", "diplomatic"]
```

---

### Fix 4 — Clothing stores invisible (wrong class)

**Hidden POIs: ~49**

The `poi_shop` catch-all filters on `class: shop`. Clothing stores in OMT have `class: clothing_store` — a separate class — so they were never rendered. A dedicated layer was added:

```json
{
  "id": "poi_clothing",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "minzoom": 14,
  "filter": ["==", "class", "clothing_store"],
  "layout": {
    "icon-image": "clothing_store_11",
    ...
  }
}
```

---

### Fix 5 — Automotive POIs had no layer

**Hidden POIs: ~81**

OSM automotive POIs (`class: car`) have three subclasses that all appeared in the data:

| Subclass | Count | Description |
|---|---|---|
| `car` | 29 | Car dealers |
| `car_repair` | 26 | Repair shops |
| `car_parts` | 26 | Parts suppliers |

A dedicated layer was added matching all three via `class: car`:

```json
{
  "id": "poi_car",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "minzoom": 14,
  "filter": ["==", "class", "car"],
  "layout": {
    "icon-image": "car_11",
    ...
  }
}
```

---

### Fix 6 — Grocery filter missed 3 subclasses

**Hidden POIs: ~48**

```json
// Before
"filter": ["in", "subclass", "supermarket", "convenience", "grocery"]

// After
"filter": ["in", "subclass", "supermarket", "convenience", "grocery", "marketplace", "department_store", "greengrocer"]
```

| Added subclass | Count |
|---|---|
| `department_store` | 19 |
| `marketplace` | 16 |
| `greengrocer` | 13 |

---

### Fix 7 — Nightclub missing from bar filter

**Hidden POIs: ~5**

```json
// Before
"filter": ["in", "subclass", "bar", "pub", "biergarten"]

// After
"filter": ["in", "subclass", "bar", "pub", "biergarten", "nightclub"]
```

---

## Summary

| Fix | Layer | POIs unlocked |
|---|---|---|
| Wrong mosque subclass | `poi_mosque` + `poi_worship` | ~106 |
| Town hall variants | `poi_town_hall` | ~260 |
| Wrong embassy subclass | `poi_embassy` | ~12 |
| New clothing layer | `poi_clothing` (new) | ~49 |
| New automotive layer | `poi_car` (new) | ~81 |
| Grocery variants | `poi_grocery` | ~48 |
| Nightclub in bar | `poi_bar` | ~5 |
| **Total** | | **~561** |

---

## OSM POI Layer Reference

The OMT `poi` layer uses this class/subclass structure. Key classes found in Algeria:

| Class | Notable subclasses |
|---|---|
| `place_of_worship` | `muslim`, `christian`, `jewish` |
| `town_hall` | `town_hall`, `townhall`, `government`, `community_centre`, `courthouse` |
| `office` | `company`, `insurance`, `telecommunication`, `lawyer`, `architect` |
| `car` | `car`, `car_repair`, `car_parts` |
| `clothing_store` | `clothes`, `bag` |
| `hospital` | `hospital`, `clinic`, `nursing_home` |
| `school` | `school`, `kindergarten` |
| `college` | `college`, `university` |
| `lodging` | `hotel`, `motel`, `hostel`, `dormitory`, `guest_house` |
| `grocery` | `supermarket`, `convenience`, `marketplace`, `department_store`, `greengrocer` |
| `shop` | `computer`, `kiosk`, `mobile_phone`, `electronics`, `hardware`, `florist`, ... |
| `pitch` | `soccer`, `tennis`, `basketball`, `volleyball`, `handball` |
| `bar` | `bar`, `pub`, `nightclub` |
| `post` | `post_office`, `post_box` |

---

## Overlap with Overture Source

The OSM and Overture layers are completely independent sources in MapLibre:
- OSM layers: `"source": "openmaptiles"`, `"source-layer": "poi"`
- Overture layers: `"source": "overture"`, `"source-layer": "place"`

Where both sources contain the same real-world place, MapLibre collision detection keeps the highest-priority label (the OSM typed layer, which appears earlier in the stack) and suppresses the other. This is correct behavior — it shows the best available data without visual clutter.
