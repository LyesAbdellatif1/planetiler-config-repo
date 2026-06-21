# Docker wrapper for bulk-import-pois.py
# Runs the Python import script inside a python:3.11-slim container
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/import-pois.ps1 --csv data/my-pois.csv [--retile] [--no-backup]
#
# The CSV path must be relative to the project root (or an absolute path under the project root).

$ROOT = Split-Path $PSScriptRoot -Parent

# Pass all args through to the Python script
$pyArgs = $args -join " "

if (-not $pyArgs -or $pyArgs -notmatch "--csv") {
    Write-Host ""
    Write-Host "Usage: npm run import:pois -- --csv <path-to-csv> [--retile] [--no-backup]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The CSV path must be relative to the project root, e.g.:"
    Write-Host "  npm run import:pois -- --csv data/my-bus-stops.csv"
    Write-Host "  npm run import:pois -- --csv data/my-bus-stops.csv --retile"
    Write-Host ""
    Write-Host "Required CSV columns: name, lat, lon, subclass"
    Write-Host "Optional columns:     confidence, notes"
    Write-Host ""
    Write-Host "See docs/POI_MANAGEMENT.md for the full guide."
    exit 0
}

# Resolve Windows project root to Docker path
$dockerRoot = $ROOT -replace "\\", "/" -replace "^([A-Z]):", { "/$($_.Value[0].ToString().ToLower())" }

Write-Host "Running bulk-import-pois.py via Docker ..." -ForegroundColor Cyan
Write-Host "Args: $pyArgs" -ForegroundColor Gray

docker run --rm `
    -v "${dockerRoot}:/project" `
    -w /project `
    python:3.11-slim `
    python scripts/bulk-import-pois.py $pyArgs.Split(" ")

if ($LASTEXITCODE -ne 0) {
    Write-Host "Import failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

if ($pyArgs -match "--retile") {
    Write-Host ""
    Write-Host "Note: --retile inside Docker only updates the GeoJSON. Run 'npm run retile:custom' to re-tile." -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\retile-custom.ps1"
}
