const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const crypto = require('crypto');

function must(name, v) {
  if (!v) throw new Error(`Missing ${name}`);
  return v;
}

function sha1(buf) {
  return crypto.createHash('sha1').update(buf).digest('hex').slice(0, 12);
}

function norm(s) {
  return (s || '').replace(/\r/g, '').replace(/\t/g, ' ').replace(/[ ]{2,}/g, ' ').trim();
}

function listStepJpgs(dir) {
  return fs.readdirSync(dir)
    .filter(f => /^step-\d+\.jpg$/i.test(f))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
}

function checkTesseract() {
  const r = spawnSync('tesseract', ['--version'], { encoding: 'utf8' });
  return r.status === 0;
}

function ocrImage(filePath, lang) {
  // tesseract <image> stdout -l eng
  const r = spawnSync('tesseract', [filePath, 'stdout', '-l', lang], { encoding: 'utf8', maxBuffer: 50 * 1024 * 1024 });
  if (r.status !== 0) {
    throw new Error(`tesseract failed for ${path.basename(filePath)}: ${r.stderr || r.stdout || ''}`);
  }
  return r.stdout || '';
}

function parseQuestion(ocrText) {
  const lines = ocrText.split('\n').map(l => norm(l)).filter(Boolean);
  const filtered = lines.filter(l => !/terms of (use|service)|privacy policy/i.test(l));
  // Prefer line containing '?'
  const q = filtered.find(l => /\?/.test(l) && !/choose as many/i.test(l));
  return q || filtered.find(l => l.length >= 6) || '';
}

(async () => {
  const srcDir = must('SRC_DIR', process.env.SRC_DIR);
  const lang = process.env.OCR_LANG || 'eng';
  const outPath = path.join(srcDir, 'ocr.json');

  if (!checkTesseract()) {
    throw new Error(
      'tesseract is not installed or not on PATH.\n' +
      'Install it first:\n' +
      '  Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y tesseract-ocr\n' +
      '  macOS (brew): brew install tesseract\n' +
      '\n' +
      'If you want the agent to install it automatically, run the above command (requires sudo access).\n'
    );
  }

  const files = listStepJpgs(srcDir);
  if (!files.length) throw new Error(`No step-*.jpg files found in ${srcDir}`);

  const steps = [];

  for (const f of files) {
    const stepMatch = f.match(/step-(\d+)\.jpg/i);
    const step = stepMatch ? Number(stepMatch[1]) : null;
    const filePath = path.join(srcDir, f);
    const buf = fs.readFileSync(filePath);

    const text = ocrImage(filePath, lang);
    const question = parseQuestion(text);

    steps.push({
      step,
      file: f,
      sha1: sha1(buf),
      question,
      ocrText: text
    });

    process.stdout.write(`ocr ${f}\n`);
  }

  const payload = { srcDir, lang, createdAt: new Date().toISOString(), steps };
  fs.writeFileSync(outPath, JSON.stringify(payload, null, 2));
  process.stdout.write(`wrote ${outPath}\n`);
})();
