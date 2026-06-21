# Troubleshooting Guide

Common errors encountered when setting up TileServer GL with sprites and fonts, and their exact fixes.

---

## Blank/Missing Regions on the Map

### Error: Entire regions are blank white (no roads, buildings, or textures)

**Symptom**

Specific geographic areas — west Algeria (Oran, Tlemcen), far west (Tindouf), or deep south (Sahara) — render as blank white with no map features at all. East (Annaba, Constantine) and center (Algiers) work fine.

**Root cause**

The `--bounds` flag passed to Planetiler was too narrow, so tiles for those regions were never generated. The MBTiles file simply does not contain those tiles — it is not a style or rendering issue.

The original incorrect bounds `2,18,9,37` started at **2°E longitude**, cutting off everything west of that line. Oran is at −0.6°E, Tlemcen at −1.3°E, and Tindouf at −8.1°E — all excluded.

**Diagnose**

Run the coverage script to confirm which regions are missing:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/diagnose-coverage.ps1
```

Also check the bounds stored in the MBTiles metadata:

```powershell
sqlite3 data\algeria.mbtiles "SELECT value FROM metadata WHERE name='bounds';"
# Correct value: -9.5,18.5,9.5,37.5
```

**Fix**

The bounds are set in two places — both must match:

1. `planetiler-config.json` line 8:
   ```json
   "bounds": [-9.5, 18.5, 9.5, 37.5]
   ```

2. `scripts/run-planetiler.ps1`:
   ```powershell
   --bounds=-9.5,18.5,9.5,37.5
   ```

Then regenerate tiles:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/run-planetiler.ps1
```

After regeneration, restart TileServer GL:
```powershell
docker-compose restart
```

---

### Error: Planetiler fails with `Input/output error` during `osm_pass1`

**Symptom**
```
java.io.IOException: Input/output error
  at ArrayLongLongMapMmap$Segment.flushToDisk
```

**Root cause**

`--nodemap-type=array` preallocates disk space proportional to the maximum OSM node ID globally (~76 GB), regardless of how much of the world you are tiling. This exhausts available disk space on most machines.

**Fix**

Use `--nodemap-type=sparsearray` instead. It only stores node IDs that are actually referenced by your input data, reducing disk usage to ~2–3 GB for Algeria:

```powershell
docker run --rm -v "c:/ProjectsRepo/planetiler-config-repo/data:/data" `
  -e JAVA_TOOL_OPTIONS="-Xmx6g" `
  ghcr.io/onthegomap/planetiler:latest `
  --osm-path=/data/algeria-latest.osm.pbf `
  --output=/data/algeria.mbtiles `
  --bounds=-9.5,18.5,9.5,37.5 `
  --minzoom=0 --maxzoom=14 `
  --nodemap-type=sparsearray `
  --storage=mmap --force
```

`scripts/run-planetiler.ps1` already uses `sparsearray` by default.

---

## Sprites

### Error: `GET /sprites/osm-liberty.json 404`

**Symptom**
```
tileserver-1  | GET /sprites/osm-liberty.json 404 163 - 7.322 ms
tileserver-1  | GET /sprites/osm-liberty.png 404 162 - 7.085 ms
tileserver-1  | mlgl: {
tileserver-1  |   class: 'Style',
tileserver-1  |   severity: 'ERROR',
tileserver-1  |   text: 'Failed to load sprite: unsupported image type'
tileserver-1  | }
```

**Root cause**

TileServer GL v5 source (`serve_style.js` line 343):
```js
if (!isValidHttpUrl(styleJSON.sprite)) {
  // Only registers local sprite files if the value is NOT an HTTP URL
}
```

If the style's `sprite` field is an absolute HTTP URL (e.g. `http://localhost:8080/sprites/osm-liberty`), TileServer GL **skips registering the local sprite files entirely** and passes the URL through unchanged — but it never actually serves that endpoint, so every request gets 404.

**Fix**

In `osm-liberty-style.json`, change the sprite value from an absolute URL to just the sprite name:

```json
// WRONG - TileServer GL ignores local files and 404s
"sprite": "http://localhost:8080/sprites/osm-liberty"

// CORRECT - TileServer GL registers the file and serves it automatically
"sprite": "osm-liberty"
```

With a relative name, TileServer GL:
1. Resolves it to `{paths.sprites}/osm-liberty` → `/data/sprites/osm-liberty`
2. Serves sprites at `/styles/osm-liberty/sprite.json` and `/styles/osm-liberty/sprite.png`
3. Rewrites the URL in the served style automatically

**Verify the fix**
```powershell
Invoke-WebRequest http://localhost:8080/styles/osm-liberty/sprite.json
# Should return 200 with sprite metadata JSON
```

---

### Error: Sprites 404 even with correct style

**Symptom**

Sprite is set to a relative name but still 404ing.

**Checklist**

1. Confirm sprite files exist on the host:
   ```powershell
   Get-ChildItem data\sprites\
   # Expected: osm-liberty.json, osm-liberty.png, osm-liberty@2x.json, osm-liberty@2x.png
   ```

2. Confirm they're visible inside the container:
   ```powershell
   docker exec planetiler-config-repo-tileserver-1 ls /data/sprites/
   ```

3. Confirm `tileserver-gl-config.json` uses absolute paths for sprites:
   ```json
   {
     "options": {
       "paths": {
         "root": "/data",
         "sprites": "/data/sprites"
       }
     }
   }
   ```

4. If files are missing, re-run the download script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/setup-sprites.ps1
   ```

---

### Error: Downloaded sprite files not found (404 on download)

**Symptom**
```
WARNING: Could not download osm-bright.json : 404: Not Found
```

**Root cause**

The original script used `osm-bright.*` filenames, but the OSM Liberty repository uses `osm-liberty.*`.

**Fix**

The correct download URLs are:
```
https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.json
https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.png
https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.json
https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.png
```

Run the corrected script:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup-sprites.ps1
```

---

## Fonts

### Error: Font glyphs 404

**Symptom**

Labels don't appear on the map, or browser console shows font requests returning 404.

**Root cause**

The style's `glyphs` URL was pointing to the wrong path:
```json
// WRONG
"glyphs": "http://localhost:8080/data/glyphs/{fontstack}/{range}.pbf"

// CORRECT
"glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf"
```

TileServer GL serves fonts at `/fonts/`, not `/data/glyphs/`.

**Fix**

In `osm-liberty-style.json`:
```json
"glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf"
```

**Verify the fix**
```powershell
Invoke-WebRequest "http://localhost:8080/fonts/Open Sans Regular/0-255.pbf"
# Should return 200 with binary PBF data
```

---

### Error: Fonts directory empty or missing

**Symptom**

Fonts endpoint returns 404 for all requests.

**Checklist**

1. Check fonts exist:
   ```powershell
   (Get-ChildItem data\fonts -Filter "*.pbf" -Recurse).Count
   # Expected: 2560
   ```

2. If missing, run the download script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/download-fonts.ps1
   ```

3. Check `tileserver-gl-config.json` points to the right directory:
   ```json
   {
     "options": {
       "paths": {
         "root": "/data",
         "fonts": "/data/fonts"
       }
     }
   }
   ```

4. Verify from inside the container:
   ```powershell
   docker exec planetiler-config-repo-tileserver-1 ls /data/fonts/
   # Should list: Open Sans Regular, Open Sans Bold, Noto Sans Regular, etc.
   ```

---

### Error: Font download URL 404

**Symptom**
```
WARNING: Could not download fonts: 404
```

**Root cause**

The original script used `https://github.com/openmaptiles/fonts/releases/download/v1.0/fonts.zip` which does not exist. The correct asset name at v1.0 is `v1.0.zip`, and the recommended release is v2.0.

**Fix**

Use the v2.0 `noto-open-sans.zip` which includes both Open Sans and Noto Sans:
```
https://github.com/openmaptiles/fonts/releases/download/v2.0/noto-open-sans.zip
```

Run the corrected script:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/download-fonts.ps1
```

---

## Style File

### Error: `center: array length 2 expected, length 3 found`

**Symptom**
```
tileserver-1  | The file "osm-liberty-style.json" is not a valid style file:
tileserver-1  | undefined: center: array length 2 expected, length 3 found
```

**Root cause**

In the MapLibre style spec, `center` takes exactly `[longitude, latitude]`. A zoom value was mistakenly included as a third element.

**Fix**

In `osm-liberty-style.json`:
```json
// WRONG
"center": [5.5, 28.0, 4],
"zoom": 4

// CORRECT
"center": [5.5, 28.0],
"zoom": 4
```

---

## TileServer GL Config

### Error: Style loads but tiles/sprites/fonts all fail

**Symptom**

Server starts but everything is broken. No clear single error.

**Root cause**

The `tileserver-gl-config.json` structure was wrong — `styles` and `data` were nested under `options` instead of being top-level keys.

**Wrong structure:**
```json
{
  "options": {
    "styles": { ... },   // WRONG - nested under options
    "data": { ... }      // WRONG - nested under options
  }
}
```

**Correct structure:**
```json
{
  "options": {
    "paths": {
      "root": "/data",
      "fonts": "/data/fonts",
      "sprites": "/data/sprites",
      "styles": "/data",
      "mbtiles": "/data"
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

---

## Docker

### Error: `npm install -g tileserver-gl` fails (canvas/Python)

**Symptom**
```
npm error gyp ERR! find Python Python is not set from command line or npm configuration
npm error gyp ERR! configure error
npm error gyp ERR! stack Error: Could not find any Python installation to use
```

**Root cause**

The `tileserver-gl` npm package includes a `canvas` native module that requires Python and build tools to compile from source. These are not available in the `node:alpine` Docker base image.

**Fix**

Do not build TileServer GL from npm. Use the official pre-built Docker image instead:

```yaml
# docker-compose.yml
services:
  tileserver:
    image: maptiler/tileserver-gl:latest   # pre-built, no npm install needed
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
      - ./tileserver-gl-config.json:/data/config.json
      - ./osm-liberty-style.json:/data/osm-liberty-style.json
```

---

### Error: `version` attribute warning

**Symptom**
```
level=warning msg="docker-compose.yml: the attribute `version` is obsolete"
```

**Fix**

Remove the `version:` line from `docker-compose.yml`. It is no longer used in Compose v2+.

---

## Clean Startup Checklist

Before running `docker-compose up`, verify:

```powershell
# 1. Sprite files exist
Get-ChildItem data\sprites\osm-liberty*
# Expected: 4 files (.json, .png, @2x.json, @2x.png)

# 2. Font files exist
(Get-ChildItem data\fonts -Filter "*.pbf" -Recurse).Count
# Expected: 2560

# 3. MBTiles exists
Get-Item data\algeria.mbtiles
# Expected: ~286 MB file

# 4. Style sprite field is relative (not HTTP URL)
Select-String -Path osm-liberty-style.json -Pattern '"sprite"'
# Expected: "sprite": "osm-liberty"

# 5. Style glyphs path is correct
Select-String -Path osm-liberty-style.json -Pattern '"glyphs"'
# Expected: "glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf"
```

Then start:
```powershell
docker-compose up -d
```

**Expected clean startup log:**
```
Starting tileserver-gl v5.6.0
Using specified config file from /data/config.json
Starting server
Listening at http://[::]:8080/
[INFO] Loading data source 'algeria' from: /data/algeria.mbtiles
Startup complete
```

No errors, no warnings about style, no 404s for sprites or fonts.

**Verify endpoints after startup:**
```powershell
# Tiles
Invoke-WebRequest http://localhost:8080/data/algeria.json

# Style
Invoke-WebRequest http://localhost:8080/styles/osm-liberty/style.json

# Sprites
Invoke-WebRequest http://localhost:8080/styles/osm-liberty/sprite.json

# Fonts
Invoke-WebRequest "http://localhost:8080/fonts/Open Sans Regular/0-255.pbf"
```

All should return `StatusCode: 200`.