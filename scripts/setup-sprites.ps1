# Setup Sprites and Icons for TileServer GL
# PowerShell equivalent of setup-sprites.sh

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path (Split-Path $PSCommandPath)
$SpritesDir = "$ProjectDir\data\sprites"
$IconsDir   = "$ProjectDir\data\icons"

Write-Host "=================================================="
Write-Host "TileServer GL Sprite Setup"
Write-Host "=================================================="
Write-Host ""

New-Item -ItemType Directory -Force -Path $SpritesDir | Out-Null
New-Item -ItemType Directory -Force -Path $IconsDir   | Out-Null

Write-Host "Downloading OSM Liberty sprites (includes Maki icons)..."

$SpriteUrls = @(
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.json",
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.png",
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.json",
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.png"
)

foreach ($Url in $SpriteUrls) {
    $Filename = [System.IO.Path]::GetFileName($Url)
    Write-Host "  Downloading $Filename..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile "$SpritesDir\$Filename" -UseBasicParsing
        Write-Host "  OK $Filename"
    } catch {
        Write-Warning "  Could not download $Filename : $_"
    }
}

Write-Host ""
Write-Host "Creating iconset configuration..."

@'
{
  "icons": {
    "poi": {
      "shop": "shop",
      "restaurant": "restaurant",
      "cafe": "cafe",
      "bar": "bar",
      "hotel": "hotel",
      "parking": "parking",
      "fuel": "fuel",
      "hospital": "hospital",
      "school": "school",
      "post": "post",
      "bank": "bank",
      "attraction": "attraction",
      "museum": "museum",
      "zoo": "zoo"
    },
    "transportation": {
      "bus": "bus",
      "train": "train",
      "airport": "airport",
      "ferry": "ferry",
      "taxi": "taxi"
    },
    "infrastructure": {
      "water": "water",
      "power": "power",
      "construction": "construction"
    }
  },
  "colors": {
    "primary": "#5d60be",
    "secondary": "#4898ff",
    "accent": "#d97200",
    "danger": "#ba3827",
    "success": "#76a723",
    "warning": "#d97200"
  }
}
'@ | Set-Content -Path "$IconsDir\iconset.json" -Encoding utf8

Write-Host "Creating icon category mappings..."

@'
{
  "amenity": {
    "shop": "shop",
    "supermarket": "shop",
    "bakery": "shop",
    "restaurant": "restaurant",
    "cafe": "cafe",
    "bar": "bar",
    "pub": "bar",
    "hotel": "hotel",
    "guest_house": "hotel",
    "hostel": "hotel",
    "parking": "parking",
    "fuel": "fuel",
    "gas_station": "fuel",
    "hospital": "hospital",
    "clinic": "hospital",
    "pharmacy": "hospital",
    "school": "school",
    "university": "school",
    "post_office": "post",
    "bank": "bank",
    "atm": "bank",
    "fountain": "attraction",
    "theatre": "attraction",
    "museum": "museum",
    "zoo": "zoo",
    "cinema": "attraction",
    "library": "school"
  },
  "tourism": {
    "hotel": "hotel",
    "guest_house": "hotel",
    "hostel": "hotel",
    "attraction": "attraction",
    "museum": "museum",
    "zoo": "zoo",
    "viewpoint": "attraction",
    "picnic_site": "park",
    "information": "information"
  },
  "transport": {
    "bus_stop": "bus",
    "bus_station": "bus",
    "train_station": "train",
    "airport": "airport",
    "ferry_terminal": "ferry",
    "taxi": "taxi",
    "parking": "parking"
  }
}
'@ | Set-Content -Path "$IconsDir\categories.json" -Encoding utf8

Write-Host "Creating POI layer examples..."

@'
{
  "poi-icons-layer": {
    "id": "poi-icons",
    "type": "symbol",
    "source": "openmaptiles",
    "source-layer": "poi",
    "filter": ["!=", "name", ""],
    "layout": {
      "icon-image": ["concat", ["get", "maki"], "-15"],
      "icon-size": [
        "interpolate", ["linear"], ["zoom"],
        0, 0.5, 10, 0.8, 14, 1.0, 18, 1.5
      ],
      "icon-allow-overlap": false,
      "text-field": ["get", "name"],
      "text-font": ["Open Sans Regular"],
      "text-size": 12,
      "text-offset": [0, 1.2],
      "text-anchor": "top",
      "icon-anchor": "bottom"
    },
    "paint": {
      "text-color": "#626262",
      "text-halo-color": "#ffffff",
      "text-halo-width": 1
    }
  }
}
'@ | Set-Content -Path "$IconsDir\poi-layers.json" -Encoding utf8

Write-Host ""
Write-Host "=================================================="
Write-Host "Sprite Setup Complete!"
Write-Host "=================================================="
Write-Host ""
Write-Host "Files created:"
Get-ChildItem $SpritesDir, $IconsDir | ForEach-Object { Write-Host "   $_" }
Write-Host ""
Write-Host "Next steps:"
Write-Host "   1. Start TileServer GL"
Write-Host "   2. Sprites served at: http://localhost:8080/sprites/osm-liberty"
Write-Host "   3. Add POI layers from data/icons/poi-layers.json to your style"
