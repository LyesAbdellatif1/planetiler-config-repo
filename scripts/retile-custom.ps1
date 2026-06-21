# Re-tile custom-pois.geojson and restart TileServer
# Run after any update to data/custom-pois.geojson

$ROOT = Split-Path $PSScriptRoot -Parent
$GEOJSON = "$ROOT\data\custom-pois.geojson"
$MBTILES = "$ROOT\data\custom-algeria.mbtiles"

if (-not (Test-Path $GEOJSON)) {
    Write-Host "ERROR: $GEOJSON not found. Run 'npm run import:pois' first." -ForegroundColor Red
    exit 1
}

# Check feature count
$sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
$geojsonData = Get-Content $GEOJSON -Raw | ConvertFrom-Json
$featureCount = $geojsonData.features.Count

Write-Host "Custom POIs: $featureCount features" -ForegroundColor Cyan

if ([int]$featureCount -eq 0) {
    Write-Host "No features in custom-pois.geojson. Creating empty placeholder MBTiles ..." -ForegroundColor Yellow

    if ($sqliteCmd) {
        $sql = @"
CREATE TABLE IF NOT EXISTS metadata (name TEXT, value TEXT);
CREATE TABLE IF NOT EXISTS tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB);
CREATE UNIQUE INDEX IF NOT EXISTS tile_index ON tiles(zoom_level, tile_column, tile_row);
INSERT OR REPLACE INTO metadata VALUES ('name', 'custom');
INSERT OR REPLACE INTO metadata VALUES ('format', 'pbf');
INSERT OR REPLACE INTO metadata VALUES ('minzoom', '12');
INSERT OR REPLACE INTO metadata VALUES ('maxzoom', '14');
"@
        $sql | & $sqliteCmd.Source $MBTILES
        Write-Host "Empty placeholder created: $MBTILES" -ForegroundColor Green
    } else {
        Write-Host "sqlite3 not found. Add POIs first, then re-run." -ForegroundColor Yellow
    }
    exit 0
}

# Backup existing MBTiles
if (Test-Path $MBTILES) {
    $ts = Get-Date -Format "yyyyMMdd-HHmm"
    $bak = "$MBTILES.bak-$ts"
    Copy-Item $MBTILES $bak
    Write-Host "Backup: $bak" -ForegroundColor Gray
}

# Convert Windows path to Docker-compatible path (PS 5.1 compatible)
$dataPath = "$ROOT\data"
$driveLetter = $dataPath[0].ToString().ToLower()
$dataDir = $driveLetter + ":" + ($dataPath.Substring(2) -replace "\\", "/")

Write-Host "Running tippecanoe ..." -ForegroundColor Cyan
docker run --rm `
    -v "${dataDir}:/data" `
    klokantech/tippecanoe tippecanoe `
    --output=/data/custom-algeria.mbtiles `
    --force `
    --minimum-zoom=12 `
    --maximum-zoom=14 `
    --layer=place `
    --drop-densest-as-needed `
    --name="Custom POIs Algeria" `
    --attribution="Custom operator data" `
    /data/custom-pois.geojson

if ($LASTEXITCODE -ne 0) {
    Write-Host "tippecanoe failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

Write-Host "Restarting TileServer ..." -ForegroundColor Cyan
docker compose -f "$ROOT\docker-compose.yml" restart tileserver

Write-Host ""
Write-Host "Done. Verifying ..." -ForegroundColor Green
powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\verify-mbtiles-visual.ps1"
