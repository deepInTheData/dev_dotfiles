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

function norm(s) {
  return (s || '').replace(/\s+/g, ' ').trim();
}

function envBool(name, def) {
  const v = process.env[name];
  if (v == null) return def;
  return ['1', 'true', 'yes', 'on'].includes(String(v).toLowerCase());
}

async function fetchMarkdownViaJina(url) {
  const jinaUrl = `https://r.jina.ai/${url}`;
  const res = await fetch(jinaUrl, {
    redirect: 'follow',
    headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; OpenClaw AdvertorialSwiper/1.0)'
    }
  });
  if (!res.ok) throw new Error(`r.jina.ai fetch failed ${res.status}: ${await res.text()}`);
  return await res.text();
}

function looksLikeBillingFieldInfo(info) {
  const f = (x) => String(x || '').toLowerCase();
  const hay = [
    f(info.name),
    f(info.id),
    f(info.placeholder),
    f(info.ariaLabel),
    f(info.label),
    f(info.autocomplete),
    f(info.type)
  ].join(' ');

  // Heuristics: a checkout page will often contain these.
  if (/card number|cc-number|credit card|debit card|cvv|cvc|security code|expiration|expiry|exp date/.test(hay)) return true;
  if (/billing address|billing|zip|postal|address line|street|city|state|province/.test(hay) && /billing|payment|card|checkout/.test(hay)) return true;
  if (/payment/.test(hay) && /(card|cvv|cvc|expiry|expiration)/.test(hay)) return true;

  return false;
}

async function detectFormFields(page) {
  return await page.evaluate(() => {
    function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
    const out = [];
    const els = Array.from(document.querySelectorAll('input,select,textarea'));

    for (const el of els) {
      const type = (el.getAttribute('type') || '').toLowerCase();
      const name = el.getAttribute('name') || '';
      const id = el.getAttribute('id') || '';
      const placeholder = el.getAttribute('placeholder') || '';
      const ariaLabel = el.getAttribute('aria-label') || '';
      const autocomplete = el.getAttribute('autocomplete') || '';

      const label = (() => {
        if (id) {
          const lab = document.querySelector(`label[for="${CSS.escape(id)}"]`);
          if (lab) return norm(lab.innerText);
        }
        // Sometimes label wraps the input
        const parentLabel = el.closest('label');
        if (parentLabel) return norm(parentLabel.innerText);
        return '';
      })();

      out.push({ tag: el.tagName.toLowerCase(), type, name, id, placeholder, ariaLabel, autocomplete, label });
    }

    return out;
  });
}

async function pageHasBillingForm(page) {
  // Many checkouts embed card fields in an iframe (e.g. CheckoutChamp/Stripe).
  const url = page.url();
  if (/secure-checkout|checkout/i.test(url)) return true;

  const fields = await detectFormFields(page);
  if (fields.some(looksLikeBillingFieldInfo)) return true;

  // Heuristics for embedded payment iframes / hidden CC fields.
  const hasPaymentIframe = await page.evaluate(() => {
    const iframes = Array.from(document.querySelectorAll('iframe'));
    return iframes.some(f => {
      const src = (f.getAttribute('src') || '').toLowerCase();
      const name = (f.getAttribute('name') || '').toLowerCase();
      const allow = (f.getAttribute('allow') || '').toLowerCase();
      return (
        allow.includes('payment') ||
        name.includes('cc') ||
        name.includes('secured') ||
        src.includes('checkout') ||
        src.includes('payment') ||
        src.includes('stripe')
      );
    });
  });

  if (hasPaymentIframe) return true;

  const hasHiddenCc = await page.evaluate(() => {
    const names = ['cardNumber', 'cardMonth', 'cardYear', 'cardSecurityCode'];
    return names.some(n => document.querySelector(`input[name="${CSS.escape(n)}"]`));
  });

  return Boolean(hasHiddenCc);
}

async function pickCtaAndClick(page) {
  // Scroll to bottom (user request). Then try to click a likely CTA.
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(1000);

  // Common CTA phrases in advertorials.
  const patterns = [
    /check (my )?availability( now)?/i,
    /special offer/i,
    /get (my )?discount/i,
    /claim (my )?(offer|discount)/i,
    /get started/i,
    /continue/i,
    /(buy now|order now)/i,
    /checkout/i,
    /where to get/i,
    /official website/i
  ];

  // Best-effort: click via Playwright locators first (will auto-scroll into view).
  for (const re of patterns) {
    try {
      const btn = page.getByRole('button', { name: re });
      if (await btn.count()) {
        await btn.first().click({ timeout: 15000 });
        return { clickedText: String(re) };
      }
    } catch (_) {}

    try {
      const link = page.getByRole('link', { name: re });
      if (await link.count()) {
        await link.first().click({ timeout: 15000 });
        return { clickedText: String(re) };
      }
    } catch (_) {}

    try {
      const any = page.getByText(re);
      if (await any.count()) {
        await any.first().click({ timeout: 15000 });
        return { clickedText: String(re) };
      }
    } catch (_) {}
  }

  // Fallback: scan visible clickable elements at the bottom and click the first match.
  const candidates = await page.evaluate(() => {
    function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
    function visible(el) {
      const r = el.getBoundingClientRect();
      if (!r || r.width < 5 || r.height < 5) return false;
      const s = window.getComputedStyle(el);
      if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
      return r.bottom > 0 && r.right > 0;
    }

    const els = Array.from(document.querySelectorAll('button,[role="button"],a,input[type="button"],input[type="submit"]'));
    const out = [];
    for (const el of els) {
      if (!visible(el)) continue;
      const txt = norm(el.innerText || el.getAttribute('value') || el.getAttribute('title') || '');
      if (!txt) continue;
      const r = el.getBoundingClientRect();
      out.push({ text: txt, x: r.x + r.width / 2, y: r.y + r.height / 2 });
    }
    out.sort((a, b) => b.y - a.y);
    return out.slice(0, 80);
  });

  const fallbackRes = [
    /check (my )?availability/i,
    /special offer/i,
    /(buy now|order now|checkout)/i,
    /continue/i
  ];

  for (const re of fallbackRes) {
    const hit = candidates.find(c => re.test(c.text));
    if (!hit) continue;
    try {
      await page.mouse.click(hit.x, hit.y);
      return { clickedText: hit.text, fallback: true };
    } catch (_) {}
  }

  // Last resort: click the bottom-most candidate.
  if (candidates.length) {
    try {
      await page.mouse.click(candidates[0].x, candidates[0].y);
      return { clickedText: candidates[0].text, fallback: true };
    } catch (_) {}
  }

  return { clickedText: null };
}

async function clickNextCommerceStep(page) {
  // After the advertorial, continue through sales/checkout.
  const patterns = [
    /get\s*\d+%\s*discount/i,
    /discount/i,
    /try .*risk[- ]?free/i,
    /risk[- ]?free/i,
    /(checkout|proceed to checkout)/i,
    /(continue|next)/i,
    /(buy now|order now)/i,
    /(complete order|place order)/i,
    /(submit)/i
  ];

  // Prefer Playwright locators (auto-scroll).
  for (const re of patterns) {
    try {
      const btn = page.getByRole('button', { name: re });
      if (await btn.count()) {
        await btn.first().click({ timeout: 15000 });
        return { clickedText: String(re) };
      }
    } catch (_) {}

    try {
      const link = page.getByRole('link', { name: re });
      if (await link.count()) {
        await link.first().click({ timeout: 15000 });
        return { clickedText: String(re) };
      }
    } catch (_) {}
  }

  // Fallback: click a visible candidate.
  const candidates = await page.evaluate(() => {
    function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
    function visible(el) {
      const r = el.getBoundingClientRect();
      if (!r || r.width < 5 || r.height < 5) return false;
      const s = window.getComputedStyle(el);
      if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
      return r.bottom > 0 && r.right > 0;
    }
    const els = Array.from(document.querySelectorAll('button,[role="button"],a,input[type="button"],input[type="submit"]'));
    const out = [];
    for (const el of els) {
      if (!visible(el)) continue;
      const txt = norm(el.innerText || el.getAttribute('value') || el.getAttribute('title') || '');
      if (!txt) continue;
      const r = el.getBoundingClientRect();
      out.push({ text: txt, x: r.x + r.width / 2, y: r.y + r.height / 2 });
    }
    out.sort((a, b) => b.y - a.y);
    return out.slice(0, 80);
  });

  const fallbackRes = [
    /discount/i,
    /risk[- ]?free/i,
    /(checkout|continue|next|buy|order)/i
  ];

  for (const re of fallbackRes) {
    const hit = candidates.find(c => re.test(c.text));
    if (!hit) continue;
    try {
      await page.mouse.click(hit.x, hit.y);
      return { clickedText: hit.text, fallback: true };
    } catch (_) {}
  }

  return { clickedText: null };
}

async function snapshotStep(page, outDir, stepNum) {
  const base = `step-${String(stepNum).padStart(2, '0')}`;
  const htmlPath = path.join(outDir, `${base}.html`);
  const metaPath = path.join(outDir, `${base}.json`);

  const url = page.url();
  const title = await page.title().catch(() => null);

  const waitMs = Number(process.env.WAIT_BEFORE_SCREENSHOT_MS || 2000);
  const doMarkdown = envBool('CAPTURE_MARKDOWN', true);

  // Always start at the top for deterministic capture.
  try {
    await page.evaluate(() => window.scrollTo(0, 0));
  } catch (_) {}

  // Screenshot policy:
  // - Step 1 (advertorial): above-the-fold only (no scrolling)
  // - Steps after: full page screenshot (captures the whole sales/checkout page)
  await page.waitForTimeout(waitMs);
  const jpgName = `${base}.jpg`;
  const jpgPath = path.join(outDir, jpgName);
  await page.screenshot({
    path: jpgPath,
    type: 'jpeg',
    quality: Number(process.env.JPG_QUALITY || 82),
    fullPage: stepNum > 1
  });

  const html = await page.content().catch(() => null);
  if (html) fs.writeFileSync(htmlPath, html);

  let mdFile = null;
  if (doMarkdown) {
    const md = await fetchMarkdownViaJina(url);
    mdFile = `${base}.md`;
    fs.writeFileSync(path.join(outDir, mdFile), md);
  }

  const images = [jpgName];

  const billing = await pageHasBillingForm(page).catch(() => false);

  fs.writeFileSync(metaPath, JSON.stringify({
    step: stepNum,
    url,
    title,
    screenshots: images,
    hasBillingForm: billing,
    capturedAt: new Date().toISOString()
  }, null, 2));

  return {
    url,
    title,
    images,
    html: path.basename(htmlPath),
    md: mdFile,
    meta: path.basename(metaPath),
    hasBillingForm: billing
  };
}

(async () => {
  const startUrl = process.argv[2];
  if (!startUrl) {
    console.error('Usage: node scripts/swipe.js <advertorial_url>');
    process.exit(2);
  }

  const baseOut = process.env.OUT_DIR || path.join(process.cwd(), 'outputs');
  const runId = process.env.RUN_ID || `${Date.now()}`;
  const key = process.env.SWIPE_KEY || sha1(startUrl);
  const outDir = path.join(baseOut, `run-${key}-${runId}`);
  fs.mkdirSync(outDir, { recursive: true });

  const viewport = {
    width: Number(process.env.VIEWPORT_W || 1280),
    height: Number(process.env.VIEWPORT_H || 720)
  };

  const maxPages = Number(process.env.MAX_PAGES || 8);
  const stopAtBilling = envBool('STOP_AT_BILLING', true);

  const results = {
    startUrl,
    viewport,
    maxPages,
    stopAtBilling,
    pages: [],
    stoppedReason: null,
    createdAt: new Date().toISOString()
  };

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();

  page.on('dialog', async (d) => {
    try { await d.accept(); } catch (_) {}
  });

  try {
    await page.goto(startUrl, { waitUntil: 'domcontentloaded', timeout: 90000 });
    await page.waitForTimeout(1200);

    for (let step = 1; step <= maxPages; step++) {
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(800);

      const snap = await snapshotStep(page, outDir, step);
      results.pages.push(snap);
      fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(results, null, 2));

      if (stopAtBilling && snap.hasBillingForm) {
        results.stoppedReason = 'billing-form-detected';
        break;
      }

      // Choose how to advance:
      // step 1: advertorial -> scroll bottom + CTA click
      // step >=2: commerce flow -> try common checkout buttons
      const prevUrl = page.url();
      let clickInfo = null;

      if (step === 1) {
        clickInfo = await pickCtaAndClick(page);
      } else {
        clickInfo = await clickNextCommerceStep(page);
      }

      // If no button clicked, we stop.
      if (!clickInfo || !clickInfo.clickedText) {
        results.stoppedReason = step === 1 ? 'no-cta-found' : 'no-next-step-found';
        break;
      }

      // Wait for either navigation or URL/DOM change
      await Promise.race([
        page.waitForNavigation({ timeout: 20000 }).catch(() => null),
        page.waitForFunction((u) => location.href !== u, prevUrl, { timeout: 20000 }).catch(() => null),
        page.waitForTimeout(20000)
      ]);

      // If we didn't move anywhere, stop to avoid loops.
      if (page.url() === prevUrl) {
        results.stoppedReason = 'click-did-not-advance';
        break;
      }
    }

    results.finalUrl = page.url();
    results.stoppedReason = results.stoppedReason || 'max-pages';

  } catch (e) {
    results.stoppedReason = 'error';
    results.error = String(e && e.stack || e);
    results.finalUrl = results.finalUrl || page.url();
  } finally {
    fs.writeFileSync(path.join(outDir, 'results.json'), JSON.stringify(results, null, 2));
    await browser.close().catch(() => null);
  }

  process.stdout.write(JSON.stringify({ outDir, finalUrl: results.finalUrl, stoppedReason: results.stoppedReason }, null, 2) + '\n');
})();
