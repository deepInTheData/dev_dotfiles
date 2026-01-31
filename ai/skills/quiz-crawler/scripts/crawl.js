const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

function norm(s) {
  return (s || '').replace(/\s+/g, ' ').trim();
}

const IGNORE_TEXT_RE = /^(terms of use|terms of service|privacy policy)$/i;
const IGNORE_CONTAINS_RE = /(terms of use|privacy policy)/i;

function safeWrite(filePath, content) {
  try { fs.writeFileSync(filePath, content); } catch (_) {}
}

function envBool(name, def) {
  const v = process.env[name];
  if (v == null) return def;
  return ['1','true','yes','on'].includes(String(v).toLowerCase());
}

(async () => {
  const url = process.argv[2];
  if (!url) {
    console.error('Usage: node scripts/crawl.js <url>');
    process.exit(2);
  }

  const outDir = process.env.OUT_DIR || path.join(process.cwd(), 'outputs', `run-${Date.now()}`);
  const maxSteps = Number(process.env.MAX_STEPS || 40);
  const maxTimeMs = Number(process.env.MAX_TIME_MS || 300000);
  const screenshotQuality = Number(process.env.JPG_QUALITY || 80);

  // Deterministic fake data (can override via env)
  const FILL_FORMS = envBool('FILL_FORMS', true);
  const NAME = process.env.FILL_NAME || 'Gin Hunter';
  const EMAIL = process.env.FILL_EMAIL || 'gin@gmail.com';
  const PHONE = process.env.FILL_PHONE || '4155552671';
  const DOB = process.env.FILL_DOB || '1990-01-01';

  fs.mkdirSync(outDir, { recursive: true });

  let browser, context, page;

  const results = {
    startUrl: url,
    steps: [],
    finalUrl: null,
    stoppedReason: null,
    createdAt: new Date().toISOString(),
    settings: { maxSteps, maxTimeMs, screenshotQuality, FILL_FORMS, NAME, EMAIL, PHONE, DOB },
    dialogs: [],
    popups: []
  };

  const seen = new Set();
  let stopping = false;

  function writeResults() {
    safeWrite(path.join(outDir, 'results.json'), JSON.stringify(results, null, 2));
  }

  async function stop(reason) {
    if (stopping) return;
    stopping = true;
    results.stoppedReason = results.stoppedReason || reason || 'stopped';
    try { results.finalUrl = results.finalUrl || (page ? page.url() : null); } catch (_) {}
    // If we still don't have a finalUrl, use last step URL.
    if (!results.finalUrl && results.steps.length) results.finalUrl = results.steps[results.steps.length - 1].url;
    writeResults();
    try { if (browser) await browser.close(); } catch (_) {}
  }

  process.on('SIGTERM', () => stop('sigterm'));
  process.on('SIGINT', () => stop('sigint'));
  process.on('exit', () => {
    // Best-effort final write for reproducibility.
    if (!results.stoppedReason) results.stoppedReason = 'exit';
    if (!results.finalUrl && results.steps.length) results.finalUrl = results.steps[results.steps.length - 1].url;
    writeResults();
  });

  const timer = setTimeout(() => stop('timeout'), maxTimeMs);

  async function snapshot(step) {
    const base = `step-${String(step).padStart(2, '0')}`;
    const jpgPath = path.join(outDir, `${base}.jpg`);
    const htmlPath = path.join(outDir, `${base}.html`);

    await page.screenshot({
      path: jpgPath,
      fullPage: true,
      type: 'jpeg',
      quality: screenshotQuality
    });

    try {
      const html = await page.content();
      safeWrite(htmlPath, html);
    } catch (_) {}

    return { screenshot: path.basename(jpgPath), html: path.basename(htmlPath) };
  }

  async function detectFields() {
    return await page.evaluate(() => {
      function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
      const fields = [];
      const els = Array.from(document.querySelectorAll('input,select,textarea'));

      for (const el of els) {
        const type = (el.getAttribute('type') || '').toLowerCase();
        const name = el.getAttribute('name') || '';
        const id = el.getAttribute('id') || '';
        const ph = el.getAttribute('placeholder') || '';
        const aria = el.getAttribute('aria-label') || '';
        const label = (() => {
          if (id) {
            const lab = document.querySelector(`label[for="${CSS.escape(id)}"]`);
            if (lab) return norm(lab.innerText);
          }
          return '';
        })();

        const key = `${name} ${id} ${ph} ${aria} ${label}`.toLowerCase();
        const looksDate = type === 'date' || type === 'datetime-local' || type === 'month' || type === 'week' ||
          key.includes('date') || key.includes('birth') || key.includes('dob') || key.includes('mm/dd') || key.includes('yyyy') || key.includes('date-picker');

        const looksEmail = type === 'email' || key.includes('email');
        const looksPhone = type === 'tel' || key.includes('phone');
        const looksName = key.includes('name') && !looksEmail;

        fields.push({
          tag: el.tagName.toLowerCase(),
          type: type || null,
          name: name || null,
          id: id || null,
          placeholder: ph || null,
          ariaLabel: aria || null,
          label: label || null,
          required: el.hasAttribute('required') || el.getAttribute('aria-required') === 'true',
          looksDate,
          looksEmail,
          looksPhone,
          looksName
        });
      }

      return {
        total: fields.length,
        datePickers: fields.filter(f => f.looksDate),
        fields
      };
    });
  }

  async function fillForms(fieldInfo) {
    if (!FILL_FORMS) return { filled: {} };

    const filled = { name: false, email: false, phone: false, dob: false };

    // Date picker policy: ALWAYS pick a random date (user requested).
    const shouldFillDob = true;

    const inputs = page.locator('input,textarea');
    const n = await inputs.count();

    for (let i = 0; i < Math.min(n, 80); i++) {
      const el = inputs.nth(i);
      let type = '';
      let name = '';
      let id = '';
      let ph = '';
      try {
        type = ((await el.getAttribute('type')) || '').toLowerCase();
        name = (await el.getAttribute('name')) || '';
        id = (await el.getAttribute('id')) || '';
        ph = (await el.getAttribute('placeholder')) || '';
      } catch (_) {}

      const key = `${name} ${id} ${ph}`.toLowerCase();

      try {
        if (!filled.email && (type === 'email' || key.includes('email'))) {
          await el.fill(EMAIL);
          filled.email = true;
          continue;
        }
        if (!filled.phone && (type === 'tel' || key.includes('phone'))) {
          await el.fill(PHONE);
          filled.phone = true;
          continue;
        }

        // Date picker: only if required. Prefer clicking a random visible day rather than typing a DOB.
        if (!filled.dob && shouldFillDob && (type === 'date' || key.includes('dob') || key.includes('birth') || key.includes('date-picker') || key.includes('date'))) {
          // Try opening the widget.
          try { await el.click({ timeout: 2000 }); } catch (_) {}
          await page.waitForTimeout(300);

          // Click a random day cell if a calendar is present.
          const clickedCalendarDay = await page.evaluate(() => {
            function visible(el) {
              const r = el.getBoundingClientRect();
              if (!r || r.width < 5 || r.height < 5) return false;
              const s = window.getComputedStyle(el);
              if (s.display === 'none' || s.visibility === 'hidden' || s.opacity === '0') return false;
              return true;
            }
            const candidates = [];
            const selectors = [
              '[role="gridcell"]',
              'button[aria-label*="day" i]',
              'button:has-text("1")',
            ];
            for (const sel of selectors) {
              for (const el of Array.from(document.querySelectorAll(sel))) {
                if (!visible(el)) continue;
                const t = (el.textContent || '').trim();
                if (/^\d{1,2}$/.test(t)) candidates.push(el);
              }
            }
            if (!candidates.length) return false;
            const pick = candidates[Math.floor(Math.random() * candidates.length)];
            pick.click();
            return true;
          });

          if (!clickedCalendarDay) {
            // Fallback: set a deterministic value only when required.
            try { await el.fill(DOB); } catch (_) {
              try {
                await el.evaluate((node, v) => {
                  node.value = v;
                  node.dispatchEvent(new Event('input', { bubbles: true }));
                  node.dispatchEvent(new Event('change', { bubbles: true }));
                }, DOB);
              } catch (_) {}
            }
          }

          filled.dob = true;
          continue;
        }

        if (!filled.name && (key.includes('name') || ph.toLowerCase().includes('name'))) {
          await el.fill(NAME);
          filled.name = true;
          continue;
        }
      } catch (_) {}
    }

    return { filled, shouldFillDob };
  }

  async function extractQuestion() {
    const candidates = await page.locator('h1,h2,[role="heading"]').all();
    for (const h of candidates.slice(0, 15)) {
      const txt = norm(await h.innerText().catch(() => ''));
      if (txt && txt.length >= 4 && !IGNORE_CONTAINS_RE.test(txt)) return txt;
    }
    const title = await page.title().catch(() => '');
    return norm(title) || null;
  }

  async function extractOptions() {
    const items = await page.evaluate(() => {
      function isVisible(el) {
        const r = el.getBoundingClientRect();
        if (!r || r.width < 5 || r.height < 5) return false;
        const style = window.getComputedStyle(el);
        if (style.visibility === 'hidden' || style.display === 'none' || style.opacity === '0') return false;
        if (r.bottom < 0 || r.right < 0) return false;
        return true;
      }
      function norm(s) { return (s || '').replace(/\s+/g, ' ').trim(); }
      const els = Array.from(document.querySelectorAll('button,[role="button"],a,div,span'));
      const out = [];
      for (const el of els) {
        if (!isVisible(el)) continue;
        const txt = norm(el.innerText || '');
        if (!txt) continue;
        if (txt.length > 80) continue;
        if (txt.split(' ').length > 12) continue;

        const tag = el.tagName.toLowerCase();
        const style = window.getComputedStyle(el);
        const cursor = style.cursor;
        const isClickable = tag === 'button' || el.getAttribute('role') === 'button' || tag === 'a' || cursor === 'pointer' || typeof el.onclick === 'function';
        if (!isClickable) continue;

        const r = el.getBoundingClientRect();
        out.push({ text: txt, tag, x: Math.round(r.x), y: Math.round(r.y) });
      }
      out.sort((a, b) => a.y - b.y);
      return out;
    });

    const seenText = new Set();
    const options = [];
    for (const it of items) {
      const t = norm(it.text);
      if (!t) continue;
      const k = t.toLowerCase();
      if (seenText.has(k)) continue;
      seenText.add(k);
      options.push(it);
    }

    return options.filter(o => !IGNORE_TEXT_RE.test(o.text) && !IGNORE_CONTAINS_RE.test(o.text));
  }

  async function clickByText(text) {
    const locators = [
      page.getByRole('button', { name: text, exact: true }),
      page.getByText(text, { exact: true }),
      page.getByText(text, { exact: false })
    ];
    for (const loc of locators) {
      try {
        if (await loc.count()) {
          await loc.first().click({ timeout: 10000 });
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  async function clickPrimaryCtaIfPresent() {
    const patterns = [
      /^(continue|next|submit|ok|done)$/i,
      /(get results|see results|view results)/i,
      /(claim|start)/i
    ];
    // Try buttons first
    const btn = page.locator('button,[role="button"],input[type="submit"],input[type="button"]');
    const n = await btn.count();
    for (let i = 0; i < Math.min(n, 50); i++) {
      const el = btn.nth(i);
      const t = norm(await el.innerText().catch(() => '')) || norm(await el.getAttribute('value').catch(() => ''));
      if (!t) continue;
      if (!patterns.some(re => re.test(t))) continue;
      try {
        await el.click({ timeout: 5000 });
        return t;
      } catch (_) {}
    }
    return null;
  }

  async function chooseAndAdvance(options) {
    const byText = (t) => options.find(o => o.text.toLowerCase() === t.toLowerCase());
    const continueOpt = byText('continue') || byText('next');

    const answerOptions = options.filter(o => !/^(continue|next)$/i.test(o.text));
    const nonSkipAnswers = answerOptions.filter(o => !/^skip/i.test(o.text));
    const firstAnswer = nonSkipAnswers[0] || answerOptions[0] || null;

    let pickedAnswer = firstAnswer ? firstAnswer.text : null;
    let advancedBy = null;

    if (firstAnswer) {
      if (!(await clickByText(firstAnswer.text))) {
        try { await page.mouse.click(firstAnswer.x + 10, firstAnswer.y + 10); } catch (_) {}
      }
      await page.waitForTimeout(300);
      advancedBy = firstAnswer.text;
    }

    if (continueOpt) {
      if (await clickByText(continueOpt.text)) {
        advancedBy = continueOpt.text;
        return { pickedAnswer, advancedBy };
      }
      try {
        await page.mouse.click(continueOpt.x + 10, continueOpt.y + 10);
        advancedBy = continueOpt.text;
      } catch (_) {}
    }

    return { pickedAnswer, advancedBy };
  }

  try {
    browser = await chromium.launch({ headless: true });
    context = await browser.newContext({ viewport: { width: 1280, height: 720 } });

    page = await context.newPage();

    // Close popup windows (but do NOT close the main page)
    page.on('popup', async (p) => {
      results.popups.push(p.url());
      p.on('dialog', async (d) => {
        results.dialogs.push({ type: d.type(), message: d.message(), when: new Date().toISOString(), page: p.url() });
        try { await d.accept(); } catch (_) {}
      });
      try { await p.close(); } catch (_) {}
    });

    page.on('dialog', async (d) => {
      results.dialogs.push({ type: d.type(), message: d.message(), when: new Date().toISOString(), page: page.url() });
      try { await d.accept(); } catch (_) {}
    });

    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 90000 });

    for (let step = 1; step <= maxSteps; step++) {
      if (stopping) break;
      await page.waitForLoadState('domcontentloaded');
      await page.waitForTimeout(700);

      const curUrl = page.url();
      const domMarker = await page.evaluate(() => {
        const txt = (document.body?.innerText || '').replace(/\s+/g, ' ').trim();
        return txt.slice(0, 350);
      });
      const fp = curUrl + '::' + domMarker;
      if (seen.has(fp)) {
        results.stoppedReason = 'loop-detected';
        results.finalUrl = curUrl;
        break;
      }
      seen.add(fp);

      const fieldInfo = await detectFields();
      const fillInfo = await fillForms(fieldInfo);
      const snap = await snapshot(step);

      const question = await extractQuestion();
      const options = await extractOptions();

      results.steps.push({
        step,
        url: curUrl,
        title: await page.title().catch(() => null),
        question,
        options: options.map(o => o.text),
        pickedAnswer: null,
        advancedBy: null,
        screenshot: snap.screenshot,
        html: snap.html,
        datePickers: fieldInfo.datePickers,
        filled: fillInfo.filled
      });

      writeResults();

      const bodyText = (await page.locator('body').innerText().catch(() => '')).toLowerCase();
      if (/(checkout|add to cart|order now|buy now)/.test(bodyText)) {
        results.finalUrl = curUrl;
        results.stoppedReason = 'offer-keyword';
        break;
      }

      if (!options.length) {
        // Popups/modals sometimes show only inputs + a submit/continue CTA.
        const cta = await clickPrimaryCtaIfPresent();
        if (cta) {
          results.steps[results.steps.length - 1].advancedBy = cta;
          writeResults();
          await Promise.race([
            page.waitForNavigation({ timeout: 15000 }).catch(() => null),
            page.waitForFunction((prev) => {
              const txt = (document.body?.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 350);
              return txt && txt !== prev;
            }, domMarker, { timeout: 15000 }).catch(() => null),
            page.waitForTimeout(15000)
          ]);
          continue;
        }

        results.finalUrl = curUrl;
        results.stoppedReason = 'no-options';
        break;
      }

      // advance
      const choice = await chooseAndAdvance(options);

      // Store what we clicked for this step (answer + what advanced the flow)
      if (choice) {
        results.steps[results.steps.length - 1].pickedAnswer = choice.pickedAnswer;
        results.steps[results.steps.length - 1].advancedBy = choice.advancedBy;
        writeResults();
      }

      // Many quiz builders use hash navigation with no real navigation event.
      // Wait for either navigation OR DOM marker change.
      await Promise.race([
        page.waitForNavigation({ timeout: 15000 }).catch(() => null),
        page.waitForFunction((prev) => {
          const txt = (document.body?.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 350);
          return txt && txt !== prev;
        }, domMarker, { timeout: 15000 }).catch(() => null),
        page.waitForTimeout(15000)
      ]);
    }

    results.finalUrl = results.finalUrl || page.url();
    results.stoppedReason = results.stoppedReason || 'max-steps';

  } catch (e) {
    results.stoppedReason = results.stoppedReason || 'error';
    results.error = String(e && e.stack || e);
    try { results.finalUrl = results.finalUrl || (page ? page.url() : null); } catch (_) {}
  } finally {
    clearTimeout(timer);
    await stop(results.stoppedReason || 'done');
  }

  console.log(JSON.stringify({ outDir, finalUrl: results.finalUrl, stoppedReason: results.stoppedReason }, null, 2));
})();
