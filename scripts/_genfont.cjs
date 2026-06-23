// Generate Mapbox/MapLibre glyph PBFs (256-codepoint ranges) from a TTF/OTF font.
// Used to add an Arabic-capable font to data/fonts so Arabic station labels render.
// (.cjs because the repo package.json sets "type": "module".)
//
// Usage (inside a node container with fontnik installed):
//   node scripts/_genfont.cjs <font.ttf> "<output dir>"
//
// Produces <output dir>/<start>-<end>.pbf for every range 0..65535.

const fs = require("fs");
const path = require("path");
const fontnik = require("fontnik");

const ttfPath = process.argv[2];
const outDir = process.argv[3];

if (!ttfPath || !outDir) {
  console.error('Usage: node _genfont.cjs <font.ttf> "<output dir>"');
  process.exit(1);
}

const font = fs.readFileSync(ttfPath);
fs.mkdirSync(outDir, { recursive: true });

let start = 0;
function next() {
  if (start > 65535) {
    console.log("Done:", outDir);
    return;
  }
  const end = start + 255;
  fontnik.range({ font, start, end }, (err, data) => {
    if (err) throw err;
    fs.writeFileSync(path.join(outDir, `${start}-${end}.pbf`), data);
    start += 256;
    next();
  });
}
next();
