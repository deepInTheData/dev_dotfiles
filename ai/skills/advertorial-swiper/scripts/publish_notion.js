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

function chunkString(str, maxLen) {
  const out = [];
  let i = 0;
  while (i < str.length) {
    out.push(str.slice(i, i + maxLen));
    i += maxLen;
  }
  return out;
}

function stripMdImages(md) {
  // Replace any markdown/HTML image tags with a sentinel token so we can render
  // a divider + "IMAGE HERE" + divider in Notion.
  return String(md || '')
    .replace(/!\[[^\]]*\]\([^\)]+\)/g, '\n---\nIMAGE HERE\n---\n')
    .replace(/<img[^>]*>/gi, '\n---\nIMAGE HERE\n---\n');
}

function mdInlineToRichText(line) {
  // Minimal markdown inline renderer for Notion rich_text.
  // Supports: **bold**, __bold__, *italic*, _italic_, `code`
  // Does NOT handle nested/overlapping edge cases perfectly; aims for "good enough".
  const s = String(line || '');
  const out = [];

  let i = 0;
  let buf = '';
  const state = { bold: false, italic: false, code: false };

  function flush() {
    if (!buf) return;
    out.push({
      type: 'text',
      text: { content: buf },
      annotations: {
        bold: state.bold,
        italic: state.italic,
        code: state.code,
        strikethrough: false,
        underline: false,
        color: 'default'
      }
    });
    buf = '';
  }

  while (i < s.length) {
    // code
    if (s[i] === '`') {
      flush();
      state.code = !state.code;
      i += 1;
      continue;
    }

    // bold
    if (!state.code && (s.startsWith('**', i) || s.startsWith('__', i))) {
      flush();
      state.bold = !state.bold;
      i += 2;
      continue;
    }

    // italic
    if (!state.code && (s[i] === '*' || s[i] === '_')) {
      // Avoid treating ** as italic (already handled)
      if (s.startsWith('**', i) || s.startsWith('__', i)) {
        // handled above
      } else {
        flush();
        state.italic = !state.italic;
        i += 1;
        continue;
      }
    }

    buf += s[i];
    i += 1;
  }

  flush();
  return out.length ? out : [{ type: 'text', text: { content: '' } }];
}

function mdToNotionBlocks(md) {
  const blocks = [];
  const lines = String(md || '').split(/\r?\n/);

  for (const raw of lines) {
    const line = raw.replace(/\t/g, '  ');
    if (!line.trim()) continue;

    // horizontal rule / divider
    if (/^(-{3,}|\*{3,})\s*$/.test(line.trim())) {
      blocks.push({ object: 'block', type: 'divider', divider: {} });
      continue;
    }

    // headings
    const h = line.match(/^(#{1,3})\s+(.*)$/);
    if (h) {
      const level = h[1].length;
      const text = h[2];
      const rich = mdInlineToRichText(text);
      blocks.push({
        object: 'block',
        type: level === 1 ? 'heading_1' : (level === 2 ? 'heading_2' : 'heading_3'),
        [level === 1 ? 'heading_1' : (level === 2 ? 'heading_2' : 'heading_3')]: { rich_text: rich }
      });
      continue;
    }

    // bullet list
    const b = line.match(/^\s*[-*]\s+(.*)$/);
    if (b) {
      blocks.push({
        object: 'block',
        type: 'bulleted_list_item',
        bulleted_list_item: { rich_text: mdInlineToRichText(b[1]) }
      });
      continue;
    }

    // numbered list
    const n = line.match(/^\s*\d+\.\s+(.*)$/);
    if (n) {
      blocks.push({
        object: 'block',
        type: 'numbered_list_item',
        numbered_list_item: { rich_text: mdInlineToRichText(n[1]) }
      });
      continue;
    }

    // default paragraph
    blocks.push({
      object: 'block',
      type: 'paragraph',
      paragraph: { rich_text: mdInlineToRichText(line.trim()) }
    });
  }

  return blocks;
}

(async () => {
  const notionKey = must('NOTION_API_KEY', process.env.NOTION_API_KEY);

  // Preferred: create a NEW child page under a parent page (e.g. a Notion database page).
  // Fallback: append blocks directly to an existing page.
  const parentPageId = process.env.NOTION_PARENT_PAGE_ID || '';
  const targetPageId = process.env.NOTION_PAGE_ID || '';

  if (!parentPageId && !targetPageId) {
    throw new Error('Missing NOTION_PARENT_PAGE_ID (preferred) or NOTION_PAGE_ID (fallback)');
  }

  const srcDir = must('SRC_DIR', process.env.SRC_DIR);

  // swipe.js writes results.json (+ step-XX.*). record.js writes meta.json + page.md.
  const resultsPath = path.join(srcDir, 'results.json');
  const hasSwipeResults = fs.existsSync(resultsPath);

  let meta = null;
  let md = null;

  if (hasSwipeResults) {
    const r = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));
    meta = {
      startUrl: r.startUrl || null,
      finalUrl: r.finalUrl || (r.pages && r.pages.length ? r.pages[r.pages.length - 1].url : null),
      title: (r.pages && r.pages.length ? (r.pages[r.pages.length - 1].title || null) : null)
    };
  } else {
    meta = JSON.parse(fs.readFileSync(path.join(srcDir, 'meta.json'), 'utf8'));
    md = fs.readFileSync(path.join(srcDir, 'page.md'), 'utf8');
  }

  const title = meta.title || meta.finalUrl || meta.startUrl;

  // Prefer manifest URLs for images.
  const manifestPath = path.join(srcDir, 'r2-manifest.json');
  let urlForFile = () => null;
  if (fs.existsSync(manifestPath)) {
    const m = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    const map = new Map(m.uploaded.map(u => [u.file, u.url]));
    urlForFile = (f) => map.get(f) || null;
  }

  const children = [];

  children.push({
    object: 'block',
    type: 'heading_2',
    heading_2: { rich_text: [{ type: 'text', text: { content: 'Advertorial Swipe' } }] }
  });

  children.push({
    object: 'block',
    type: 'paragraph',
    paragraph: {
      rich_text: [
        { type: 'text', text: { content: 'Start URL: ' } },
        { type: 'text', text: { content: meta.startUrl, link: { url: meta.startUrl } } }
      ]
    }
  });

  if (meta.finalUrl && meta.finalUrl !== meta.startUrl) {
    children.push({
      object: 'block',
      type: 'paragraph',
      paragraph: {
        rich_text: [
          { type: 'text', text: { content: 'Final URL: ' } },
          { type: 'text', text: { content: meta.finalUrl, link: { url: meta.finalUrl } } }
        ]
      }
    });
  }

  children.push({
    object: 'block',
    type: 'paragraph',
    paragraph: { rich_text: [{ type: 'text', text: { content: `Title: ${title}` } }] }
  });

  // If this directory is from swipe.js, render each step.
  if (hasSwipeResults) {
    const r = JSON.parse(fs.readFileSync(resultsPath, 'utf8'));

    children.push({
      object: 'block',
      type: 'heading_3',
      heading_3: { rich_text: [{ type: 'text', text: { content: 'Pages' } }] }
    });

    for (const p of (r.pages || [])) {
      const anyImg = (p.images && p.images.length) ? p.images[0] : (p.jpg || '');
      const stepNum = String(anyImg || '').match(/step-(\d+)/i)?.[1] || null;
      const caption = stepNum ? `Step ${stepNum}` : 'Step';

      children.push({
        object: 'block',
        type: 'heading_3',
        heading_3: { rich_text: [{ type: 'text', text: { content: `${caption}: ${p.title || p.url}`.slice(0, 200) } }] }
      });

      children.push({
        object: 'block',
        type: 'paragraph',
        paragraph: {
          rich_text: [
            { type: 'text', text: { content: 'URL: ' } },
            { type: 'text', text: { content: p.url, link: { url: p.url } } }
          ]
        }
      });

      const imgFile = p.jpg || (p.images && p.images[0]) || null;
      const imgUrl = imgFile ? urlForFile(imgFile) : null;
      if (imgUrl) {
        // Put screenshots in a collapsible toggle.
        children.push({
          object: 'block',
          type: 'toggle',
          toggle: {
            rich_text: [{ type: 'text', text: { content: `${caption} — Screenshot` } }],
            children: [
              {
                object: 'block',
                type: 'image',
                image: {
                  type: 'external',
                  external: { url: imgUrl },
                  caption: [{ type: 'text', text: { content: caption } }]
                }
              }
            ]
          }
        });
      }

      // Markdown: render basic formatting (bold/italic/lists/headings) into Notion blocks.
      // Also strip markdown image tags and replace with placeholder.
      if (p.md && fs.existsSync(path.join(srcDir, p.md))) {
        const rawMd = fs.readFileSync(path.join(srcDir, p.md), 'utf8');
        const cleaned = stripMdImages(rawMd);
        const renderedBlocks = mdToNotionBlocks(cleaned);

        // Add markdown directly (not collapsible). If it's long, split into batches and append
        // as sequential blocks (Notion API still limits per request, handled by top-level batching).
        children.push({
          object: 'block',
          type: 'heading_3',
          heading_3: { rich_text: [{ type: 'text', text: { content: `${caption} — Markdown` } }] }
        });

        children.push(...renderedBlocks);
      }

      if (p.hasBillingForm) {
        children.push({
          object: 'block',
          type: 'callout',
          callout: {
            rich_text: [{ type: 'text', text: { content: 'Stopped here: billing / payment form detected.' } }],
            icon: { type: 'emoji', emoji: '🛑' }
          }
        });
      }
    }
  } else {
    // Fallback: single-page record.js output
    const screenshotUrl = urlForFile('above-the-fold.jpg');
    if (screenshotUrl) {
      children.push({
        object: 'block',
        type: 'image',
        image: { type: 'external', external: { url: screenshotUrl }, caption: [{ type: 'text', text: { content: 'Above the fold' } }] }
      });
    }

    children.push({
      object: 'block',
      type: 'heading_3',
      heading_3: { rich_text: [{ type: 'text', text: { content: 'Extracted Markdown (via r.jina.ai)' } }] }
    });

    const chunks = chunkString(md, 1800);
    for (const c of chunks) {
      children.push({
        object: 'block',
        type: 'code',
        code: {
          rich_text: [{ type: 'text', text: { content: c } }],
          language: 'markdown'
        }
      });
    }
  }

  // Create child page under parent when available.
  if (parentPageId) {
    const pageTitle = `${(title || 'Advertorial').slice(0, 120)}`;

    // Notion limits children per request. Create the page first, then append blocks in batches.
    const createPayload = {
      parent: { page_id: parentPageId },
      properties: {
        title: { title: [{ text: { content: pageTitle } }] }
      }
    };

    const page = await notionRequest('POST', '/v1/pages', notionKey, createPayload);

    const BATCH = Number(process.env.NOTION_CHILDREN_BATCH || 90);
    for (let i = 0; i < children.length; i += BATCH) {
      const batch = children.slice(i, i + BATCH);
      await notionRequest('PATCH', `/v1/blocks/${page.id}/children`, notionKey, { children: batch });
    }

    process.stdout.write(`created ${page.url}\n`);
    process.stdout.write(JSON.stringify({ pageId: page.id, url: page.url, blocks: children.length }, null, 2) + '\n');
    return;
  }

  // Fallback: append directly to an existing page.
  const payload = { children };
  const resp = await notionRequest('PATCH', `/v1/blocks/${targetPageId}/children`, notionKey, payload);
  process.stdout.write(`appended to https://www.notion.so/${targetPageId.replace(/-/g,'')}\n`);
  process.stdout.write(JSON.stringify({ results: resp.results ? resp.results.length : null }, null, 2) + '\n');
})();
