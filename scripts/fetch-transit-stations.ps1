# Docker wrapper for fetch-transit-stations.py
# Pulls Algeria metro + tram stations (with names) from OpenStreetMap (Overpass API)
# and writes data/transit-stations.geojson.
#
# Usage:
#   npm run fetch:transit
#   powershell -ExecutionPolicy Bypass -File scripts/fetch-transit-stations.ps1
#
# After this, run:  npm run retile:transit

$ROOT = Split-Path $PSScriptRoot -Parent

# Resolve Windows project root to Docker path (PS 5.1 compatible)
$driveLetter = $ROOT[0].ToString().ToLower()
$dockerRoot = $driveLetter + ":" + ($ROOT.Substring(2) -replace "\\", "/")

Write-Host "Fetching Algeria transit stations from OSM via Docker ..." -ForegroundColor Cyan

docker run --rm `
    -v "${dockerRoot}:/project" `
    -w /project `
    python:3.11-slim `
    python scripts/fetch-transit-stations.py

if ($LASTEXITCODE -ne 0) {
    Write-Host "Fetch failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done. Next: npm run retile:transit" -ForegroundColor Green
