# Re-tile transit data into data/transit-algeria.mbtiles (two layers) and restart TileServer.
# Run after 'npm run fetch:transit', which writes:
#   data/transit-stations.geojson  -> layer "transit"      (station points: tr_* layers)
#   data/transit-lines.geojson     -> layer "transitlines" (route lines:    trl_* layers)

$ROOT = Split-Path $PSScriptRoot -Parent
$GEOJSON = "$ROOT\data\transit-stations.geojson"
$LINES = "$ROOT\data\transit-lines.geojson"
$MBTILES = "$ROOT\data\transit-algeria.mbtiles"

if (-not (Test-Path $GEOJSON)) {
    Write-Host "ERROR: $GEOJSON not found. Run 'npm run fetch:transit' first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $LINES)) {
    Write-Host "ERROR: $LINES not found. Run 'npm run fetch:transit' first." -ForegroundColor Red
    exit 1
}

$featureCount = (Get-Content $GEOJSON -Raw | ConvertFrom-Json).features.Count
$lineCount = (Get-Content $LINES -Raw | ConvertFrom-Json).features.Count
Write-Host "Transit: $featureCount station points, $lineCount route lines" -ForegroundColor Cyan

if ([int]$featureCount -eq 0) {
    Write-Host "No features in transit-stations.geojson. Aborting." -ForegroundColor Red
    exit 1
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

Write-Host "Running tippecanoe (points + lines) ..." -ForegroundColor Cyan
docker run --rm `
    -v "${dataDir}:/data" `
    klokantech/tippecanoe tippecanoe `
    --output=/data/transit-algeria.mbtiles `
    --force `
    --minimum-zoom=10 `
    --maximum-zoom=14 `
    --drop-densest-as-needed `
    --name="Algeria Transit" `
    --attribution="(c) OpenStreetMap contributors" `
    --named-layer=transit:/data/transit-stations.geojson `
    --named-layer=transitlines:/data/transit-lines.geojson

if ($LASTEXITCODE -ne 0) {
    Write-Host "tippecanoe failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}

Write-Host "Restarting TileServer ..." -ForegroundColor Cyan
docker compose -f "$ROOT\docker-compose.yml" restart tileserver

Write-Host ""
Write-Host "Done. Transit stations tiled into transit-algeria.mbtiles." -ForegroundColor Green
