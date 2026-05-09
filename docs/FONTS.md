# Fonts Guide

Complete guide for setting up and using fonts in your Algerian TileServer GL setup.

## Overview

TileServer GL uses font glyphs (`.pbf` files) to render text labels on the map. This setup includes:

- **Open Sans** — Primary font for map labels (Regular, Bold, Italic variants)
- **Noto Sans** — Multilingual fallback with Arabic, Latin, and CJK support
- **2560 glyph files** — Pre-rendered at multiple Unicode ranges for fast rendering

## File Structure

```
data/
└── fonts/
    ├── Open Sans Bold/
    │   ├── 0-255.pbf
    │   ├── 256-511.pbf
    │   └── ...
    ├── Open Sans Regular/
    │   └── ...
    ├── Open Sans Italic/
    │   └── ...
    ├── Noto Sans Regular/
    │   └── ...
    └── Noto Sans Bold/
        └── ...
```

## Setup

### Download Fonts

```powershell
powershell -ExecutionPolicy Bypass -File scripts/download-fonts.ps1
```

This downloads `noto-open-sans.zip` (~64 MB) from OpenMapTiles v2.0 and extracts 2560 `.pbf` glyph files into `data/fonts/`.

### Verify Installation

```powershell
# Count font files
(Get-ChildItem data\fonts -Filter "*.pbf" -Recurse).Count

# List font families
Get-ChildItem data\fonts -Directory | Select-Object Name
```

You should see font families like:
- `Open Sans Regular`
- `Open Sans Bold`
- `Open Sans Italic`
- `Noto Sans Regular`
- `Noto Sans Bold`

## TileServer GL Configuration

Fonts are served automatically once the files exist in `data/fonts/`. TileServer GL exposes them at:

```
http://localhost:8080/fonts/{fontstack}/{range}.pbf
```

Example:
```
http://localhost:8080/fonts/Open Sans Regular/0-255.pbf
```

### config.json

The working TileServer GL config structure (fonts path is relative to `root`):

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
    "osm-liberty": { "style": "osm-liberty-style.json" }
  },
  "data": {
    "algeria": { "mbtiles": "algeria.mbtiles" }
  }
}
```

`fonts: "fonts"` resolves to `/data/fonts/` because `root` is `/data`.

## MapLibre GL Configuration

### Setting the Glyphs URL

Add to your style JSON:

```json
{
  "version": 8,
  "glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf",
  "sources": { ... },
  "layers": [ ... ]
}
```

**Remote Access** (from another device):

```json
{
  "glyphs": "http://192.168.1.100:8080/fonts/{fontstack}/{range}.pbf"
}
```

### Using Fonts in Layers

Reference fonts by their exact family name in the `text-font` layout property:

```json
{
  "id": "place-labels",
  "type": "symbol",
  "layout": {
    "text-field": ["get", "name"],
    "text-font": ["Open Sans Regular", "Noto Sans Regular"],
    "text-size": 12
  }
}
```

The array is a priority list — MapLibre uses the first font that contains the required glyph, falling back to the next.

### Font Stack Examples

```json
// Standard labels
"text-font": ["Open Sans Regular", "Noto Sans Regular"]

// Bold labels (cities, towns)
"text-font": ["Open Sans Bold", "Noto Sans Bold"]

// Italic labels (water features)
"text-font": ["Open Sans Italic", "Noto Sans Regular"]
```

### Zoom-Based Font Sizing

```json
{
  "text-size": [
    "interpolate", ["linear"], ["zoom"],
    10, 10,
    14, 12,
    18, 16
  ]
}
```

## Arabic / RTL Text Support

For Arabic place names in Algeria, MapLibre requires the RTL plugin:

```html
<script>
maplibregl.setRTLTextPlugin(
  'https://unpkg.com/@mapbox/mapbox-gl-rtl-text@0.2.3/mapbox-gl-rtl-text.min.js',
  null,
  true
);
</script>
```

Or in React Native:

```js
import MapLibreGL from '@react-native-mapbox-gl/maps';
MapLibreGL.setRTLTextPlugin('...');
```

Noto Sans includes Arabic glyphs, so once the RTL plugin is enabled, Arabic labels render correctly from OpenStreetMap data.

## Available Font Families

| Family | Weight | Use Case |
|--------|--------|----------|
| Open Sans Regular | 400 | Default map labels |
| Open Sans Bold | 700 | City names, major roads |
| Open Sans Italic | 400i | Water features, parks |
| Open Sans SemiBold | 600 | Town names |
| Noto Sans Regular | 400 | Multilingual fallback |
| Noto Sans Bold | 700 | Multilingual bold fallback |

## Troubleshooting

### Labels Not Appearing

1. Check fonts are downloaded:
   ```powershell
   Get-ChildItem data\fonts -Filter "*.pbf" -Recurse | Measure-Object
   ```

2. Verify the glyphs URL in your style matches the server:
   ```json
   { "glyphs": "http://localhost:8080/fonts/{fontstack}/{range}.pbf" }
   ```

3. Test the endpoint directly:
   ```powershell
   Invoke-WebRequest "http://localhost:8080/fonts/Open Sans Regular/0-255.pbf"
   ```

### Wrong Font Rendering

Ensure the font name in your style exactly matches the directory name in `data/fonts/`:

```powershell
# See exact font family names
Get-ChildItem data\fonts -Directory | Select-Object Name
```

### Labels Appear as Boxes (Missing Glyphs)

Add Noto Sans as a fallback — it covers a much wider Unicode range:

```json
"text-font": ["Open Sans Regular", "Noto Sans Regular"]
```

### Fonts Don't Load Remotely

Use your server's IP instead of `localhost`:

```json
{
  "glyphs": "http://192.168.1.100:8080/fonts/{fontstack}/{range}.pbf"
}
```

## Performance Notes

- All 2560 `.pbf` files are loaded on-demand per tile — only the needed Unicode ranges are fetched
- Glyph files are small (~10–40 KB each) and cached aggressively by the browser
- The `{range}` placeholder (e.g. `0-255`) means each file covers 256 Unicode code points

## Resources

- [OpenMapTiles Fonts](https://github.com/openmaptiles/fonts)
- [MapLibre GL Text Rendering](https://maplibre.org/maplibre-gl-js/docs/)
- [MapLibre RTL Text Plugin](https://github.com/mapbox/mapbox-gl-rtl-text)
- [OpenMapTiles Font Releases](https://github.com/openmaptiles/fonts/releases)

## License

- **Open Sans**: Apache 2.0
- **Noto Sans**: SIL Open Font License 1.1