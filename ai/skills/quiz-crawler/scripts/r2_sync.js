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

(async () => {
  const srcDir = must('SRC_DIR', process.env.SRC_DIR);

  const endpoint = must('R2_ENDPOINT', process.env.R2_ENDPOINT);
  const bucket = must('R2_BUCKET', process.env.R2_BUCKET);
  const publicBase = must('R2_PUBLIC_BASE', process.env.R2_PUBLIC_BASE).replace(/\/+$/, '');

  const accessKeyId = must('R2_ACCESS_KEY_ID', process.env.R2_ACCESS_KEY_ID);
  const secretAccessKey = must('R2_SECRET_ACCESS_KEY', process.env.R2_SECRET_ACCESS_KEY);
  const region = process.env.R2_REGION || 'auto';

  const runId = process.env.RUN_ID || path.basename(srcDir).replace(/^run-/, '') || String(Date.now());
  const prefixBase = (process.env.R2_PREFIX || 'quiz').replace(/^\/+/, '').replace(/\/+$/, '');
  const quizKey = process.env.QUIZ_KEY || sha1(process.env.QUIZ_URL || srcDir);
  const prefix = `${prefixBase}/${quizKey}-${runId}`;

  const includeHtml = (process.env.INCLUDE_HTML || 'true').toLowerCase() !== 'false';

  const files = fs.readdirSync(srcDir)
    .filter(f => /^step-\d+\.(jpg|jpeg|html)$/i.test(f))
    .filter(f => includeHtml || !/\.html$/i.test(f))
    .sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));

  // Always include these for reproducibility
  for (const extra of ['results.json', 'ocr.json', 'qa.json']) {
    if (fs.existsSync(path.join(srcDir, extra))) files.push(extra);
  }

  const uploaded = [];

  for (const f of files) {
    const full = path.join(srcDir, f);
    if (!fs.existsSync(full)) continue;

    const key = `${prefix}/${f}`;
    const body = fs.readFileSync(full);

    const isHtml = /\.html$/i.test(f);
    const isJpg = /\.(jpg|jpeg)$/i.test(f);

    await putObject({
      endpoint,
      bucket,
      key,
      body,
      contentType: isJpg ? 'image/jpeg' : (isHtml ? 'text/html; charset=utf-8' : 'application/json'),
      cacheControl: isJpg ? 'public, max-age=31536000, immutable' : 'public, max-age=3600',
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
