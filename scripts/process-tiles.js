#!/usr/bin/env node

/**
 * Planetiler Tile Processing Script
 * Converts Algerian OSM data to MBTiles vector tiles
 * 
 * Usage: node scripts/process-tiles.js
 * Or via npm: npm run process-tiles
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const DATA_DIR = path.join(__dirname, '..', 'data');
const OSM_FILE = path.join(DATA_DIR, 'algeria-latest.osm.pbf');
const OUTPUT_FILE = path.join(DATA_DIR, 'algeria.mbtiles');
const CONFIG_FILE = path.join(__dirname, '..', 'planetiler-config.json');

console.log('=== Planetiler Tile Generation for Algeria ===\n');

// Check if OSM data exists
if (!fs.existsSync(OSM_FILE)) {
    console.error(`❌ Error: OSM file not found at ${OSM_FILE}`);
    console.log('\nPlease run the download script first:');
    console.log('  Windows: powershell -ExecutionPolicy Bypass -File scripts/download-algeria-data.ps1');
    console.log('  Linux:   bash scripts/download-algeria-data.sh\n');
    process.exit(1);
}

console.log(`📍 Input: ${OSM_FILE}`);
console.log(`💾 Output: ${OUTPUT_FILE}`);
console.log(`⚙️  Config: ${CONFIG_FILE}\n`);

// Build Planetiler command
// Using planetiler-core docker image or local binary
const cmd = [
    'java', '-Xmx8g',
    '-jar', 'planetiler.jar',
    '--download',
    '--area', 'algeria',
    '--output', OUTPUT_FILE,
    ...( fs.existsSync(CONFIG_FILE) ? ['--config', CONFIG_FILE] : [])
];

console.log('Starting Planetiler processing...');
console.log('This may take several minutes depending on system resources.\n');

const planetiler = spawn(cmd[0], cmd.slice(1), {
    stdio: 'inherit',
    cwd: DATA_DIR
});

planetiler.on('error', (err) => {
    console.error(`\n❌ Error: Failed to start Planetiler`);
    console.error('Make sure Java is installed and planetiler.jar is available\n');
    process.exit(1);
});

planetiler.on('close', (code) => {
    if (code === 0) {
        if (fs.existsSync(OUTPUT_FILE)) {
            const stats = fs.statSync(OUTPUT_FILE);
            console.log(`\n✓ Successfully generated MBTiles: ${OUTPUT_FILE}`);
            console.log(`  File size: ${(stats.size / 1024 / 1024 / 1024).toFixed(2)} GB\n`);
            console.log('=== Next Steps ===');
            console.log('1. Start TileServer GL with your MBTiles:');
            console.log('   npm run tileserver\n');
        }
    } else {
        console.error(`\n❌ Planetiler processing failed with code ${code}`);
        process.exit(1);
    }
});
