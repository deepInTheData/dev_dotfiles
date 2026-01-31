const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { putObject } = require('./r2_sigv4_put');
const { loadDotEnv } = require('./load_env');

// Load ../.env if present (skill-local secrets)
loadDotEnv(path.join(__dirname, '..', '.env'));

function must(name, v) {
  if (!v) throw new Error(`Missing ${name}`);
  return v;
}

function sha1(s) {
  return crypto.createHash('sha1').update(String(s)).digest('hex').slice(0, 10);
}

function contentTypeFor(file) {
  const f = file.toLowerCase();
  if (f.endsWith('.jpg') || f.endsWith('.jpeg')) return 'image/jpeg';
  if (f.endsWith('.png')) return 'image/png';
  if (f.endsWith('.md')) return 'text/markdown; charset=utf-8';
  if (f.endsWith('.html')) return 'text/html; charset=utf-8';
  if (f.endsWith('.txt')) return 'text/plain; charset=utf-8';
  if (f.endsWith('.json')) return 'application/json';
  return 'application/octet-stream';
}

(async () => {
  const srcDir = must('SRC_DIR', process.env.SRC_DIR);

  const endpoint = must('R2_ENDPOINT', process.env.R2_ENDPOINT);
  const bucket = must('R2_BUCKET', process.env.R2_BUCKET);
  const publicBase = must('R2_PUBLIC_BASE', process.env.R2_PUBLIC_BASE).replace(/\/+$/, '');

  const accessKeyId = must('R2_ACCESS_KEY_ID', process.env.R2_ACCESS_KEY_ID);
  const secretAccessKey = must('R2_SECRET_ACCESS_KEY', process.env.R2_SECRET_ACCESS_KEY);
  const region = process.env.R2_REGION || 'auto';

  const runId = process.env.RUN_ID || path.basename(srcDir).replace(/^run-/, '') || String(Date.now());
  const prefixBase = (process.env.R2_PREFIX || 'page').replace(/^\/+/, '').replace(/\/+$/, '');
  const pageKey = process.env.PAGE_KEY || sha1(process.env.PAGE_URL || srcDir);
  const prefix = `${prefixBase}/${pageKey}-${runId}`;

  // Cost-saving default: upload ONLY images.
  // (We still write r2-manifest.json locally so Notion can reference public URLs.)
  const files = fs.readdirSync(srcDir)
    .filter(f => (
      /^step-\d+\.(jpg|jpeg)$/i.test(f) ||
      f === 'above-the-fold.jpg'
    ))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  const uploaded = [];

  for (const f of files) {
    const full = path.join(srcDir, f);
    if (!fs.existsSync(full)) continue;

    const key = `${prefix}/${f}`;
    const body = fs.readFileSync(full);

    const isImg = /\.(jpg|jpeg|png)$/i.test(f);

    await putObject({
      endpoint,
      bucket,
      key,
      body,
      contentType: contentTypeFor(f),
      cacheControl: isImg ? 'public, max-age=31536000, immutable' : 'public, max-age=3600',
      accessKeyId,
      secretAccessKey,
      region
    });

    const url = `${publicBase}/${key}`;
    uploaded.push({ file: f, key, url });
    process.stdout.write(`uploaded ${f}\n`);
  }

  const manifest = {
    bucket,
    prefix,
    publicBase,
    count: uploaded.length,
    uploaded,
    createdAt: new Date().toISOString()
  };

  fs.writeFileSync(path.join(srcDir, 'r2-manifest.json'), JSON.stringify(manifest, null, 2));
  process.stdout.write(`wrote ${path.join(srcDir, 'r2-manifest.json')}\n`);
})();
