# Diagnose missing tile coverage for Algeria MBTiles
# Checks whether tiles exist for key geographic locations

$ROOT = Split-Path $PSScriptRoot -Parent
$OSM_FILE = "$ROOT\data\algeria.mbtiles"

$sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
$SQLITE = if ($sqliteCmd) { $sqliteCmd.Source } else { $null }

if (-not $SQLITE) {
    Write-Host "ERROR: sqlite3 not found on PATH. Install with: choco install sqlite" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $OSM_FILE)) {
    Write-Host "ERROR: File not found: $OSM_FILE" -ForegroundColor Red
    exit 1
}

function lon-to-tile([double]$lon, [int]$zoom) {
    return [int][Math]::Floor(($lon + 180.0) / 360.0 * [Math]::Pow(2, $zoom))
}

function lat-to-tile([double]$lat, [int]$zoom) {
    $latRad = $lat * [Math]::PI / 180.0
    $n = [Math]::Pow(2, $zoom)
    return [int][Math]::Floor((1.0 - [Math]::Log([Math]::Tan($latRad) + 1.0 / [Math]::Cos($latRad)) / [Math]::PI) / 2.0 * $n)
}

# MBTiles stores tile_row in TMS format (flipped Y), convert from XYZ
function xyz-row-to-tms([int]$y, [int]$zoom) {
    return [int]([Math]::Pow(2, $zoom) - 1 - $y)
}

function Check-Tile([string]$db, [double]$lon, [double]$lat, [int]$zoom) {
    $x = lon-to-tile $lon $zoom
    $y = lat-to-tile $lat $zoom
    $tmsY = xyz-row-to-tms $y $zoom
    $sql = "SELECT COUNT(*) FROM tiles WHERE zoom_level=$zoom AND tile_column=$x AND tile_row=$tmsY;"
    $count = & $SQLITE $db $sql 2>$null
    return [int]$count -gt 0
}

Write-Host ""
Write-Host "=== Algeria MBTiles Coverage Diagnostic ===" -ForegroundColor Cyan
Write-Host "File: $OSM_FILE"
Write-Host ""

# Show actual bounds from metadata
$bounds = & $SQLITE $OSM_FILE "SELECT value FROM metadata WHERE name='bounds';" 2>$null
Write-Host "Stored bounds: $bounds" -ForegroundColor Yellow
Write-Host "Expected full Algeria: -9.5,18.5,9.5,37.5"
Write-Host ""

# Key locations: name, lon, lat
$locations = @(
    @{ Name = "Algiers (center)  "; Lon =  3.06; Lat = 36.74 },
    @{ Name = "Oran (west)       "; Lon = -0.63; Lat = 35.69 },
    @{ Name = "Tlemcen (NW)      "; Lon = -1.31; Lat = 34.88 },
    @{ Name = "Tindouf (far west)"; Lon = -8.10; Lat = 27.67 },
    @{ Name = "Tamanrasset (S)   "; Lon =  5.52; Lat = 22.78 },
    @{ Name = "In Salah (S)      "; Lon =  2.47; Lat = 27.20 },
    @{ Name = "Annaba (east)     "; Lon =  7.76; Lat = 36.90 },
    @{ Name = "Constantine (NE)  "; Lon =  6.61; Lat = 36.37 }
)

$zoom = 8
Write-Host "Checking tiles at zoom $zoom..." -ForegroundColor Cyan
Write-Host ""

foreach ($loc in $locations) {
    $found = Check-Tile $OSM_FILE $loc.Lon $loc.Lat $zoom
    if ($found) {
        Write-Host "  FOUND   $($loc.Name)  ($($loc.Lon), $($loc.Lat))" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $($loc.Name)  ($($loc.Lon), $($loc.Lat))" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Note: MISSING locations confirm tiles were not generated - fix is to re-run" -ForegroundColor Gray
Write-Host "      Planetiler with bounds=-9.5,18.5,9.5,37.5 (see scripts/run-planetiler.ps1)" -ForegroundColor Gray
Write-Host ""