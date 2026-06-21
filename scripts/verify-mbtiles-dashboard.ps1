# Generate HTML dashboard report for MBTiles files

$ROOT = Split-Path $PSScriptRoot -Parent
$OSM_FILE = "$ROOT\data\algeria.mbtiles"
$OVERTURE_FILE = "$ROOT\data\overture-algeria.mbtiles"
$OUTPUT_FILE = "$ROOT\mbtiles-dashboard.html"

$sqliteCmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqliteCmd) {
    Write-Host "sqlite3 not found - install with: choco install sqlite" -ForegroundColor Red
    exit 1
}
$SQLITE = $sqliteCmd.Source

function Get-MBTilesInfo([string]$path, [string]$label) {
    if (-not (Test-Path $path)) { return $null }

    $size = [Math]::Round((Get-Item $path).Length / 1MB, 2)
    $count = & $SQLITE $path "SELECT COUNT(*) FROM tiles;" 2>$null
    $zooms = & $SQLITE $path "SELECT GROUP_CONCAT(DISTINCT zoom_level) FROM tiles;" 2>$null
    $integrity = & $SQLITE $path "PRAGMA integrity_check;" 2>$null

    $distribution = @()
    $byZoom = & $SQLITE $path "SELECT zoom_level, COUNT(*) FROM tiles GROUP BY zoom_level ORDER BY zoom_level;" 2>$null
    foreach ($row in $byZoom) {
        $parts = $row -split "\|"
        if ($parts.Count -ge 2) {
            $distribution += @{ zoom = $parts[0].Trim(); tiles = $parts[1].Trim() }
        }
    }

    $metaRaw = & $SQLITE $path "SELECT name, value FROM metadata WHERE name NOT IN ('json','planetiler:buildtime','planetiler:githash','planetiler:osm:osmosisreplicationseq','planetiler:osm:osmosisreplicationtime','planetiler:osm:osmosisreplicationurl','planetiler:version') ORDER BY name;" 2>$null
    $metaRows = @()
    foreach ($row in $metaRaw) {
        $parts = $row -split "\|", 2
        if ($parts.Count -eq 2) {
            $metaRows += "<tr><td>$($parts[0].Trim())</td><td>$($parts[1].Trim())</td></tr>"
        }
    }

    return @{
        label        = $label
        size         = $size
        count        = $count
        zooms        = $zooms
        integrity    = $integrity
        distribution = $distribution
        metaHtml     = ($metaRows -join "`n")
    }
}

Write-Host "Reading algeria.mbtiles ..." -ForegroundColor Cyan
$osm = Get-MBTilesInfo $OSM_FILE "OSM (algeria.mbtiles)"

Write-Host "Reading overture-algeria.mbtiles ..." -ForegroundColor Cyan
$overture = Get-MBTilesInfo $OVERTURE_FILE "Overture (overture-algeria.mbtiles)"

# Build Chart.js data arrays
$osmLabels   = ($osm.distribution      | ForEach-Object { "'z$($_.zoom)'" }) -join ","
$osmData     = ($osm.distribution      | ForEach-Object { $_.tiles })        -join ","
$ovrLabels   = ($overture.distribution | ForEach-Object { "'z$($_.zoom)'" }) -join ","
$ovrData     = ($overture.distribution | ForEach-Object { $_.tiles })        -join ","

$osmStatus = if ($osm.integrity      -eq "ok") { '<span class="pass">OK</span>' } else { '<span class="fail">FAILED</span>' }
$ovrStatus = if ($overture.integrity -eq "ok") { '<span class="pass">OK</span>' } else { '<span class="fail">FAILED</span>' }

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MBTiles Dashboard</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 24px;
  }
  .container { max-width: 1200px; margin: 0 auto; }
  h1 {
    color: white;
    text-align: center;
    font-size: 2em;
    margin-bottom: 8px;
    text-shadow: 1px 2px 4px rgba(0,0,0,0.3);
  }
  .subtitle {
    color: rgba(255,255,255,0.75);
    text-align: center;
    font-size: 0.85em;
    margin-bottom: 28px;
  }
  .summary-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 16px;
    margin-bottom: 24px;
  }
  .summary-card {
    background: white;
    border-radius: 10px;
    padding: 20px;
    text-align: center;
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
  }
  .summary-value { font-size: 2em; font-weight: 700; color: #667eea; }
  .summary-label { color: #666; font-size: 0.85em; margin-top: 4px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
  .card {
    background: white;
    border-radius: 10px;
    padding: 24px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.15);
  }
  .card h2 { color: #667eea; margin-bottom: 16px; font-size: 1.2em; border-bottom: 2px solid #f0f0f0; padding-bottom: 10px; }
  .metric { display: flex; justify-content: space-between; align-items: center; padding: 9px 12px; margin: 6px 0; background: #f8f8f8; border-radius: 6px; }
  .metric-label { color: #444; font-size: 0.9em; }
  .metric-value { font-weight: 600; color: #333; }
  .pass { color: #10b981; font-weight: 700; }
  .fail { color: #ef4444; font-weight: 700; }
  .chart-container { position: relative; height: 260px; margin-top: 18px; }
  .meta-table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 0.82em; }
  .meta-table td { padding: 5px 8px; border-bottom: 1px solid #f0f0f0; }
  .meta-table td:first-child { color: #888; width: 40%; }
  .meta-table td:last-child { color: #333; word-break: break-all; }
  .full-card { margin-bottom: 20px; }
  @media (max-width: 768px) {
    .grid, .summary-grid { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>
<div class="container">
  <h1>MBTiles Dashboard</h1>
  <p class="subtitle">Generated: $generatedAt &nbsp;|&nbsp; Project: $ROOT</p>

  <div class="summary-grid">
    <div class="summary-card">
      <div class="summary-value">$($osm.count)</div>
      <div class="summary-label">OSM Tiles</div>
    </div>
    <div class="summary-card">
      <div class="summary-value">$($osm.size) MB</div>
      <div class="summary-label">OSM File Size</div>
    </div>
    <div class="summary-card">
      <div class="summary-value">$($overture.count)</div>
      <div class="summary-label">Overture Tiles</div>
    </div>
    <div class="summary-card">
      <div class="summary-value">$($overture.size) MB</div>
      <div class="summary-label">Overture File Size</div>
    </div>
  </div>

  <div class="grid">
    <div class="card">
      <h2>OSM &mdash; algeria.mbtiles</h2>
      <div class="metric"><span class="metric-label">Integrity</span><span class="metric-value">$osmStatus</span></div>
      <div class="metric"><span class="metric-label">Total Tiles</span><span class="metric-value">$($osm.count)</span></div>
      <div class="metric"><span class="metric-label">File Size</span><span class="metric-value">$($osm.size) MB</span></div>
      <div class="metric"><span class="metric-label">Zoom Levels</span><span class="metric-value">$($osm.zooms)</span></div>
      <div class="chart-container">
        <canvas id="osmChart"></canvas>
      </div>
    </div>

    <div class="card">
      <h2>Overture &mdash; overture-algeria.mbtiles</h2>
      <div class="metric"><span class="metric-label">Integrity</span><span class="metric-value">$ovrStatus</span></div>
      <div class="metric"><span class="metric-label">Total Tiles</span><span class="metric-value">$($overture.count)</span></div>
      <div class="metric"><span class="metric-label">File Size</span><span class="metric-value">$($overture.size) MB</span></div>
      <div class="metric"><span class="metric-label">Zoom Levels</span><span class="metric-value">$($overture.zooms)</span></div>
      <div class="chart-container">
        <canvas id="overtureChart"></canvas>
      </div>
    </div>
  </div>

  <div class="grid">
    <div class="card full-card">
      <h2>OSM Metadata</h2>
      <table class="meta-table">$($osm.metaHtml)</table>
    </div>
    <div class="card full-card">
      <h2>Overture Metadata</h2>
      <table class="meta-table">$($overture.metaHtml)</table>
    </div>
  </div>
</div>

<script>
  new Chart(document.getElementById('osmChart').getContext('2d'), {
    type: 'bar',
    data: {
      labels: [$osmLabels],
      datasets: [{ label: 'Tiles', data: [$osmData], backgroundColor: '#667eea', borderRadius: 4 }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { y: { beginAtZero: true, ticks: { maxTicksLimit: 6 } } }
    }
  });

  new Chart(document.getElementById('overtureChart').getContext('2d'), {
    type: 'bar',
    data: {
      labels: [$ovrLabels],
      datasets: [{ label: 'Tiles', data: [$ovrData], backgroundColor: '#764ba2', borderRadius: 4 }]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { display: false } },
      scales: { y: { beginAtZero: true, ticks: { maxTicksLimit: 6 } } }
    }
  });
</script>
</body>
</html>
"@

$html | Set-Content -Path $OUTPUT_FILE -Encoding UTF8
Write-Host "Dashboard created: $OUTPUT_FILE" -ForegroundColor Green
Start-Process $OUTPUT_FILE
