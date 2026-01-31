const fs = require('fs');
const path = require('path');

function must(name, v) { if (!v) throw new Error(`Missing ${name}`); return v; }
function norm(s){ return (s||'').replace(/\s+/g,' ').trim(); }

function extractQuestionFromOcr(step){
  const lines = (step.ocrText||'').split('\n').map(norm).filter(Boolean);
  // Prefer line with ?
  const q = lines.find(l => /\?/.test(l) && !/choose as many/i.test(l));
  return q || lines.find(l => l.length>5) || '';
}

(async () => {
  const srcDir = must('SRC_DIR', process.env.SRC_DIR);
  const results = JSON.parse(fs.readFileSync(path.join(srcDir,'results.json'),'utf8'));
  const ocr = fs.existsSync(path.join(srcDir,'ocr.json'))
    ? JSON.parse(fs.readFileSync(path.join(srcDir,'ocr.json'),'utf8'))
    : { steps: [] };

  const ocrByStep = new Map((ocr.steps||[]).map(s => [s.step, s]));

  const qa = [];

  for (const s of results.steps||[]) {
    const stepNum = s.step;
    const o = ocrByStep.get(stepNum) || {};
    // Prefer DOM-extracted options captured during crawl (more reliable than OCR).
    const options = (s.options || [])
      .map(norm)
      .filter(Boolean)
      .filter(t => !/^continue$|^next$|^back$/i.test(t))
      // drop emoji-only duplicates
      .filter(t => t.replace(/\p{Extended_Pictographic}/gu,'').trim().length > 0);

    const question = extractQuestionFromOcr(o) || norm(s.question) || '';

    qa.push({
      step: stepNum,
      url: s.url,
      question,
      options,
      pickedAnswer: s.pickedAnswer || null,
      screenshot: s.screenshot || `step-${String(stepNum).padStart(2,'0')}.jpg`,
      html: s.html || `step-${String(stepNum).padStart(2,'0')}.html`
    });
  }

  const out = { startUrl: results.startUrl, finalUrl: results.finalUrl, stoppedReason: results.stoppedReason, steps: qa };
  fs.writeFileSync(path.join(srcDir,'qa.json'), JSON.stringify(out, null, 2));
  process.stdout.write(`wrote ${path.join(srcDir,'qa.json')}\n`);
})();
