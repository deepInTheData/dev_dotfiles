const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { chromium } = require('playwright');
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

async function fetchMarkdownViaJina(url) {
  const jinaUrl = `https://r.jina.ai/${url}`;
  const res = await fetch(jinaUrl, {
    redirect: 'follow',
    headers: {
      // help some sites return full HTML to jina
      'User-Agent': 'Mozilla/5.0 (compatible; OpenClaw PageRecorder/1.0)'
    }
  });
  if (!res.ok) throw new Error(`r.jina.ai fetch failed ${res.status}: ${await res.text()}`);
  return await res.text();
}

(async () => {
  const url = process.argv[2];
  if (!url) {
    console.error('Usage: node scripts/record.js <url>');
    process.exit(2);
  }

  const baseOut = process.env.OUT_DIR || path.join(process.cwd(), 'outputs');
  const runId = process.env.RUN_ID || `${Date.now()}`;
  const key = process.env.PAGE_KEY || sha1(url);
  const outDir = path.join(baseOut, `run-${key}-${runId}`);
  fs.mkdirSync(outDir, { recursive: true });

  const viewport = {
    width: Number(process.env.VIEWPORT_W || 1280),
    height: Number(process.env.VIEWPORT_H || 720)
  };

  const startedAt = new Date().toISOString();

  // 1) Markdown via r.jina.ai
  const md = await fetchMarkdownViaJina(url);
  fs.writeFileSync(path.join(outDir, 'page.md'), md);

  // 2) Above-the-fold screenshot (no scrolling; fullPage=false)
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();

  let finalUrl = null;
  let title = null;
  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 });
    await page.waitForTimeout(1000);
    finalUrl = page.url();
    title = await page.title().catch(() => null);

    await page.screenshot({
      path: path.join(outDir, 'above-the-fold.jpg'),
      type: 'jpeg',
      quality: Number(process.env.JPG_QUALITY || 82),
      fullPage: false
    });

    const html = await page.content().catch(() => null);
    if (html) fs.writeFileSync(path.join(outDir, 'page.html'), html);
  } finally {
    await browser.close().catch(() => null);
  }

  fs.writeFileSync(path.join(outDir, 'meta.json'), JSON.stringify({
    startUrl: url,
    finalUrl,
    title,
    viewport,
    startedAt,
    finishedAt: new Date().toISOString()
  }, null, 2));

  fs.writeFileSync(path.join(outDir, 'url.txt'), `${url}\n`);

  process.stdout.write(JSON.stringify({ outDir, url, finalUrl, title }, null, 2) + '\n');
})();
