# Enhanced MBTiles verification with visual output
# Requires sqlite3 on PATH (found via Android SDK or standalone install)

$ROOT = Split-Path $PSScriptRoot -Parent
$OSM_FILE = "$ROOT\data\algeria.mbtiles"
$OVERTURE_FILE = "$ROOT\data\overture-algeria.mbtiles"

$sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
$SQLITE = if ($sqliteCmd) { $sqliteCmd.Source } else { $null }
$hasSqlite = $null -ne $SQLITE

function Run-Query([string]$db, [string]$sql) {
    if (-not $hasSqlite) { return $null }
    return (& $SQLITE $db $sql 2>$null)
}

function Write-Box([string]$title, [string]$color = "Cyan") {
    $line = "-" * ($title.Length + 4)
    Write-Host $line -ForegroundColor $color
    Write-Host "  $title" -ForegroundColor $color
    Write-Host $line -ForegroundColor $color
}

function Check-MBTiles([string]$path, [string]$label) {
    Write-Host ""
    Write-Box $label "Cyan"

    if (-not (Test-Path $path)) {
        Write-Host "  FAIL  File not found: $path" -ForegroundColor Red
        return $false
    }

    $sizeMB = [Math]::Round((Get-Item $path).Length / 1MB, 2)
    Write-Host "  Size   : $sizeMB MB" -ForegroundColor White

    if (-not $hasSqlite) {
        Write-Host "  SKIP   sqlite3 not on PATH - skipping database checks" -ForegroundColor Yellow
        return $true
    }

    # Integrity
    $integrity = Run-Query $path "PRAGMA integrity_check;"
    if ($integrity -eq "ok") {
        Write-Host "  PASS   Integrity check" -ForegroundColor Green
    } else {
        Write-Host "  FAIL   Integrity check: $integrity" -ForegroundColor Red
        return $false
    }

    # Tile count + zoom levels
    $tileCount = Run-Query $path "SELECT COUNT(*) FROM tiles;"
    $zooms = Run-Query $path "SELECT GROUP_CONCAT(DISTINCT zoom_level) FROM tiles;"
    Write-Host "  Tiles  : $tileCount" -ForegroundColor White
    Write-Host "  Zooms  : $zooms" -ForegroundColor White

    # Metadata (skip the verbose json field)
    Write-Host ""
    Write-Host "  Metadata:" -ForegroundColor Yellow
    $meta = Run-Query $path "SELECT name, value FROM metadata WHERE name NOT IN ('json','planetiler:buildtime','planetiler:githash','planetiler:osm:osmosisreplicationseq','planetiler:osm:osmosisreplicationtime','planetiler:osm:osmosisreplicationurl','planetiler:version') ORDER BY name;"
    $meta | ForEach-Object {
        $parts = $_ -split "\|", 2
        if ($parts.Count -eq 2) {
            $key = $parts[0].Trim().PadRight(16)
            $val = $parts[1].Trim()
            Write-Host "    $key $val" -ForegroundColor Gray
        }
    }

    # Bar chart by zoom
    Write-Host ""
    Write-Host "  Zoom Distribution:" -ForegroundColor Yellow
    $byZoom = Run-Query $path "SELECT zoom_level, COUNT(*) FROM tiles GROUP BY zoom_level ORDER BY zoom_level;"
    $counts = $byZoom | ForEach-Object { ($_ -split "\|")[1] -as [int] }
    $maxCount = ($counts | Measure-Object -Maximum).Maximum

    $byZoom | ForEach-Object {
        $parts = $_ -split "\|"
        $z = $parts[0].Trim()
        $cnt = [int]$parts[1].Trim()
        $barLen = if ($maxCount -gt 0) { [Math]::Round(($cnt / $maxCount) * 30) } else { 0 }
        $bar = ("#" * $barLen).PadRight(30)
        Write-Host "    z$($z.PadLeft(2))  [$bar]  $cnt" -ForegroundColor Cyan
    }

    # Largest tiles
    Write-Host ""
    Write-Host "  Top 5 Largest Tiles:" -ForegroundColor Yellow
    $large = Run-Query $path "SELECT zoom_level, tile_column, tile_row, LENGTH(tile_data) FROM tiles ORDER BY LENGTH(tile_data) DESC LIMIT 5;"
    $large | ForEach-Object {
        $p = $_ -split "\|"
        $kb = [Math]::Round([int]$p[3] / 1024, 1)
        Write-Host "    z$($p[0]) x$($p[1]) y$($p[2])  ->  $kb KB" -ForegroundColor Gray
    }

    return $true
}

# Header
Write-Host ""
Write-Host "######################################" -ForegroundColor White
Write-Host "#   MBTiles Verification Dashboard   #" -ForegroundColor White
Write-Host "######################################" -ForegroundColor White
Write-Host "  Project: $ROOT" -ForegroundColor Gray

if (-not $hasSqlite) {
    Write-Host ""
    Write-Host "  WARNING: sqlite3 not found on PATH." -ForegroundColor Yellow
    Write-Host "  Install: choco install sqlite" -ForegroundColor Yellow
}

$osmOk = Check-MBTiles $OSM_FILE "OSM (algeria.mbtiles)"
$overtureOk = Check-MBTiles $OVERTURE_FILE "Overture (overture-algeria.mbtiles)"

Write-Host ""
if ($osmOk -and $overtureOk) {
    Write-Host "  All checks passed." -ForegroundColor Green
} else {
    Write-Host "  One or more checks failed - see above." -ForegroundColor Red
    exit 1
}
Write-Host ""
