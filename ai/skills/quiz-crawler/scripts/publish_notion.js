const fs = require('fs');
const path = require('path');
const https = require('https');
const { loadDotEnv } = require('./load_env');

// Load ../.env if present (skill-local secrets)
loadDotEnv(path.join(__dirname, '..', '.env'));

function must(name, v) {
  if (!v) throw new Error(`Missing ${name}`);
  return v;
}

function norm(s) {
  return (s || '').replace(/\s+/g, ' ').trim();
}

function notionRequest(method, urlPath, token, bodyObj) {
  const body = bodyObj ? Buffer.from(JSON.stringify(bodyObj)) : null;
  return new Promise((resolve, reject) => {
    const req = https.request({
      method,
      hostname: 'api.notion.com',
      path: urlPath,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Notion-Version': '2025-09-03',
        'Content-Type': 'application/json',
        ...(body ? { 'Content-Length': body.length } : {})
      }
    }, (res) => {
      const chunks = [];
      res.on('data', c => chunks.push(c));
      res.on('end', () => {
        const txt = Buffer.concat(chunks).toString('utf8');
        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
          resolve(txt ? JSON.parse(txt) : {});
        } else {
          reject(new Error(`Notion ${res.statusCode}: ${txt}`));
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(body);
    req.end();
  });
}

(async () => {
  const notionKey = must('NOTION_API_KEY', process.env.NOTION_API_KEY);
  const parentPageId = must('NOTION_PARENT_PAGE_ID', process.env.NOTION_PARENT_PAGE_ID);

  const srcDir = must('SRC_DIR', process.env.SRC_DIR);
  const brand = process.env.BRAND || 'Quiz';
  const dateStr = process.env.DATE || new Date().toISOString().slice(0,10);

  const resultsPath = path.join(srcDir, 'results.json');
  const qaPath = path.join(srcDir, 'qa.json');
  const results = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
  const qa = fs.existsSync(qaPath) ? JSON.parse(fs.readFileSync(qaPath, 'utf8')) : null;

  // Prefer manifest URLs, fallback to public base + prefix.
  let imageUrlForStep = (stepNum) => null;
  const manifestPath = path.join(srcDir, 'r2-manifest.json');
  if (fs.existsSync(manifestPath)) {
    const m = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    const map = new Map(m.uploaded.map(u => [u.file, u.url]));
    imageUrlForStep = (n) => map.get(`step-${String(n).padStart(2,'0')}.jpg`) || null;
  } else {
    const base = must('R2_PUBLIC_BASE', process.env.R2_PUBLIC_BASE).replace(/\/+$/, '');
    const prefix = must('R2_PREFIX', process.env.R2_PREFIX).replace(/^\/+/, '').replace(/\/+$/, '');
    imageUrlForStep = (n) => `${base}/${prefix}/step-${String(n).padStart(2,'0')}.jpg`;
  }

  const children = [];

  children.push({
    object: 'block',
    type: 'paragraph',
    paragraph: { rich_text: [{ type: 'text', text: { content: `Quiz: ${results.startUrl}` } }] }
  });

  children.push({
    object: 'block',
    type: 'paragraph',
    paragraph: { rich_text: [{ type: 'text', text: { content: `Final URL: ${results.finalUrl || '(unknown)'}` } }] }
  });

  children.push({
    object: 'block',
    type: 'heading_2',
    heading_2: { rich_text: [{ type: 'text', text: { content: 'Quiz Output (Question / Answer / Screenshot)' } }] }
  });

  const steps = (qa && qa.steps) ? qa.steps : (results.steps || []);

  for (const s of steps) {
    const q = norm(s.question) || `Step ${s.step}`;
    const a = norm(s.pickedAnswer) || '(no answer picked / continue)';
    const img = imageUrlForStep(s.step);

    children.push({
      object: 'block',
      type: 'paragraph',
      paragraph: { rich_text: [{ type: 'text', text: { content: `Question: ${q}` } }] }
    });

    children.push({
      object: 'block',
      type: 'paragraph',
      paragraph: { rich_text: [{ type: 'text', text: { content: `Answer: ${a}` } }] }
    });

    if (img) {
      children.push({
        object: 'block',
        type: 'image',
        image: { type: 'external', external: { url: img }, caption: [{ type: 'text', text: { content: `Step ${String(s.step).padStart(2,'0')}` } }] }
      });
    }
  }

  const title = `Quiz Output - ${brand} (Q/A/Screenshot) ${dateStr}`;

  const payload = {
    parent: { page_id: parentPageId },
    properties: {
      title: { title: [{ text: { content: title } }] }
    },
    children
  };

  const page = await notionRequest('POST', '/v1/pages', notionKey, payload);
  process.stdout.write(`created ${page.url}\n`);
})();
