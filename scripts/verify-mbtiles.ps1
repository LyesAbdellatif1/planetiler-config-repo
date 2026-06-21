# MBTiles verification script for Algeria tileserver project
# Requires sqlite3 on PATH (found via Android SDK or standalone install)

$ROOT = Split-Path $PSScriptRoot -Parent
$OSM_FILE = "$ROOT\data\algeria.mbtiles"
$OVERTURE_FILE = "$ROOT\data\overture-algeria.mbtiles"

$sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
$SQLITE = if ($sqliteCmd) { $sqliteCmd.Source } else { $null }
$hasSqlite = $null -ne $SQLITE

function Write-Section([string]$title) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
}

function Write-Pass([string]$msg) { Write-Host "  PASS  $msg" -ForegroundColor Green }
function Write-Fail([string]$msg) { Write-Host "  FAIL  $msg" -ForegroundColor Red }
function Write-Info([string]$msg) { Write-Host "        $msg" -ForegroundColor Gray }

function Run-Query([string]$db, [string]$sql) {
    if (-not $hasSqlite) { return $null }
    return (& $SQLITE $db $sql 2>$null)
}

function Check-MBTiles([string]$path, [string]$label) {
    Write-Section $label

    if (-not (Test-Path $path)) {
        Write-Fail "File not found: $path"
        return $false
    }
    $sizeMB = [Math]::Round((Get-Item $path).Length / 1MB, 2)
    Write-Pass "File exists ($sizeMB MB)"

    if (-not $hasSqlite) {
        Write-Host "  SKIP  sqlite3 not on PATH - skipping database checks" -ForegroundColor Yellow
        return $true
    }

    $integrity = Run-Query $path "PRAGMA integrity_check;"
    if ($integrity -eq "ok") {
        Write-Pass "Integrity check passed"
    } else {
        Write-Fail "Integrity check FAILED: $integrity"
        return $false
    }

    $tileCount = Run-Query $path "SELECT COUNT(*) FROM tiles;"
    if ([int]$tileCount -gt 0) {
        Write-Pass "Tile count: $tileCount tiles"
    } else {
        Write-Fail "No tiles found - file may be empty"
    }

    $zooms = Run-Query $path "SELECT GROUP_CONCAT(DISTINCT zoom_level) FROM tiles ORDER BY zoom_level;"
    Write-Pass "Zoom levels: $zooms"

    Write-Info "--- Metadata ---"
    $meta = Run-Query $path "SELECT name || ': ' || value FROM metadata ORDER BY name;"
    $meta | ForEach-Object { Write-Info "  $_" }

    Write-Info "--- Tiles by zoom ---"
    $byZoom = Run-Query $path "SELECT 'zoom ' || zoom_level || ': ' || COUNT(*) || ' tiles' FROM tiles GROUP BY zoom_level ORDER BY zoom_level;"
    $byZoom | ForEach-Object { Write-Info "  $_" }

    Write-Info "--- Top 5 largest tiles ---"
    $large = Run-Query $path "SELECT 'z' || zoom_level || ' x' || tile_column || ' y' || tile_row || '  ' || (LENGTH(tile_data)/1024) || ' KB' FROM tiles ORDER BY LENGTH(tile_data) DESC LIMIT 5;"
    $large | ForEach-Object { Write-Info "  $_" }

    return $true
}

Write-Host ""
Write-Host "MBTiles Verification" -ForegroundColor White
Write-Host "Project: $ROOT"

if (-not $hasSqlite) {
    Write-Host ""
    Write-Host "WARNING: sqlite3 not found on PATH." -ForegroundColor Yellow
    Write-Host "Install with: choco install sqlite" -ForegroundColor Yellow
}

$osmOk = Check-MBTiles $OSM_FILE "OSM (algeria.mbtiles)"
$overtureOk = Check-MBTiles $OVERTURE_FILE "Overture (overture-algeria.mbtiles)"

Write-Host ""
if ($osmOk -and $overtureOk) {
    Write-Host "All checks passed." -ForegroundColor Green
} else {
    Write-Host "One or more checks failed - see above." -ForegroundColor Red
    exit 1
}
