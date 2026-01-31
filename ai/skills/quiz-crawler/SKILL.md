---
name: quiz-crawler
description: "Extract all questions/answer options from marketing quiz funnels and record final redirect/product URL + screenshots. Use when a user gives a quiz URL and asks to collect questions/answers or capture the offer page. Use output format specified in assets/output.md"
---

## Workflow (reproducible pipeline)

This skill is for building a **swipe database**: store raw artifacts + a clean Notion page.

### 1) Crawl (deterministic path)
Run:
- `node scripts/crawl.js "<quiz_url>"`

Popup handling:
- Auto-accepts JS dialogs (alert/confirm/prompt).
- Attempts to click modal CTAs like Continue/Submit/OK when a popup blocks progress.

Optional:
- `OUT_DIR=/path/to/output`
- `MAX_STEPS=60` (default 40)
- `MAX_TIME_MS=420000` (default 300000)
- `JPG_QUALITY=80`
- `FILL_FORMS=true|false` (default true)

Artifacts written to `OUT_DIR`:
- `results.json` (steps + pickedAnswer + stopReason + finalUrl)
- `step-XX.jpg` (screenshot per interaction)
- `step-XX.html` (HTML snapshot when available)

### 2) Sync artifacts to R2 (deterministic)
Run:
- `SRC_DIR=<OUT_DIR> node scripts/r2_sync.js`

Required env:
- `R2_ENDPOINT`
- `R2_BUCKET`
- `R2_PUBLIC_BASE` (e.g. `https://pub-....r2.dev`)
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`

Optional env:
- `R2_PREFIX` (default `quiz`)
- `RUN_ID` (otherwise derived from `SRC_DIR`)
- `QUIZ_KEY` (stable key for the funnel; otherwise derived from `SRC_DIR`)
- `INCLUDE_HTML=true|false` (default true)

Output:
- writes `r2-manifest.json` into `SRC_DIR` with public URLs.

### Setup (minimal deps)
- OCR uses the **system `tesseract` binary** (no JS OCR deps).
- If `tesseract` is missing, install it:
  - Ubuntu/Debian: `sudo apt-get update && sudo apt-get install -y tesseract-ocr`
  - macOS (brew): `brew install tesseract`

- R2 sync requires these env vars. Recommended: store them in a **skill-local `.env`** file at `~/skills/quiz-crawler/.env` (the scripts auto-load it).
  - `R2_ENDPOINT`
  - `R2_BUCKET`
  - `R2_PUBLIC_BASE`
  - `R2_ACCESS_KEY_ID`
  - `R2_SECRET_ACCESS_KEY`

- Notion publish requires:
  - `NOTION_API_KEY`
  - `NOTION_PARENT_PAGE_ID`

`.env` notes:
- Lines like `KEY=value` or `KEY="value"`.
- **Do not commit** `.env` (secrets). If you package/share the skill, exclude `.env`.

### 3) Extract Q/A via OCR (quick) + Publish Notion page
Run:
- `SRC_DIR=<OUT_DIR> node scripts/ocr_extract.js` (writes `ocr.json`)
- `SRC_DIR=<OUT_DIR> node scripts/qa_extract.js` (writes `qa.json`: OCR question + DOM options)
- `SRC_DIR=<OUT_DIR> BRAND=<BrandName> NOTION_PARENT_PAGE_ID=<page_id> node scripts/publish_notion.js`

Fast defaults:
- OCR is used only for the **question** (line containing `?`).
- Options come from the crawler’s captured button text (more reliable than OCR).

Required env:
- `NOTION_API_KEY`
- `NOTION_PARENT_PAGE_ID`

Output:
- Creates 1 Notion child page under the parent with the format specified in `assets/output.md`:
  - `Question: ...`
  - `Answer: ...`
  - `Screenshot: <external image>`

### Data handling
- Use sensible dummy data to progress:
  - name/email/phone/dates as needed.
- Date picker policy: always pick a random date when a date-picker is present.

Notes:
- This skill currently captures a **single deterministic path**. Different answers can lead to different pages; add branching only when requested.
