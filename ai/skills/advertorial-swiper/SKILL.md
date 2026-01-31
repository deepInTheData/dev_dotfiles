---
name: advertorial-swiper
description: "Swipe/record advertorial and landing pages into durable artifacts: extract markdown via r.jina.ai/URL, take an above-the-fold screenshot (no scrolling), upload artifacts to Cloudflare R2, and append the result to a Notion page. Use when a user provides an advertorial URL and wants it archived for a swipe file with screenshot + extracted markdown."
---

# Advertorial Swiper

Swipe an advertorial end-to-end into durable artifacts.

What it does:
- Loads the advertorial URL.
- Scrolls to the end of the page.
- Clicks the primary CTA (e.g. “Check availability now”, “Special offer”, etc.).
- Continues through sales/checkout steps until it detects a billing/payment form.
- For **each page/step**, captures:
  - Step 1 (advertorial): `step-01.jpg` above-the-fold screenshot (**no scrolling**)
  - Steps 2+ (offer/checkout): `step-02.jpg`, `step-03.jpg`, ... as **full-page** screenshots
  - waits a couple seconds before screenshotting (configurable)
  - `step-XX.html` (best-effort)
  - `step-XX.json` metadata (incl. billing-form detection)
  - `step-XX.md` markdown via `https://r.jina.ai/<URL>` (default on)

Then sync artifacts to R2 (public URLs) and append the results to a Notion page.

## Setup (first time only)

From the skill folder:
- `npm install`
- `npx playwright install chromium`

## Workflow

### 1) Swipe the advertorial (multi-page)
Run:
- `node scripts/swipe.js "<advertorial_url>"`

Optional env:
- `OUT_DIR=/path/to/outputs` (default `./outputs`)
- `RUN_ID=...` (otherwise uses timestamp)
- `SWIPE_KEY=...` (stable key; otherwise derived from URL)
- `MAX_PAGES=8`
- `STOP_AT_BILLING=true|false` (default true)
- `VIEWPORT_W=1280` / `VIEWPORT_H=720`
- `JPG_QUALITY=82`
- `SCROLL_SCREENSHOTS=true|false` (default true)
- `WAIT_BEFORE_SCREENSHOT_MS=2000`
- `MAX_SCREENSHOTS_PER_PAGE=30`
- `CAPTURE_MARKDOWN=true|false` (default false)

Output directory:
- `outputs/run-<swipeKey>-<runId>/...`

### 2) Upload artifacts to R2 (deterministic)
Run:
- `SRC_DIR=<outDir> node scripts/r2_sync.js`

Required env (recommend skill-local `./.env`):
- `R2_ENDPOINT`
- `R2_BUCKET`
- `R2_PUBLIC_BASE` (e.g. `https://pub-....r2.dev`)
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`

Optional env:
- `R2_PREFIX` (default `page`)

Notes:
- `r2_sync.js` uploads **only images** (JPG) to R2 to save costs.

Writes:
- `r2-manifest.json` into `SRC_DIR`

### 3) Append to Notion page
Run:
- `SRC_DIR=<outDir> node scripts/publish_notion.js`

Required env (in `./.env`):
- `NOTION_API_KEY`
- `NOTION_PARENT_PAGE_ID` (preferred)

Optional env:
- `NOTION_PAGE_ID` (fallback: append to an existing page)

Notes:
- The markdown is appended as one or more Notion `code` blocks (`language=markdown`) to avoid “markdown→Notion” conversion complexity.
- The screenshot is added as an external image (best when `r2-manifest.json` is present).
