const fs = require('fs');

// Tiny .env loader (no deps). Only sets keys that are not already set.
// Supports: KEY=value, KEY="value", ignores comments/blank lines.
function loadDotEnv(filePath) {
  if (!filePath || !fs.existsSync(filePath)) return { loaded: false, filePath };
  const text = fs.readFileSync(filePath, 'utf8');
  const lines = text.split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const idx = trimmed.indexOf('=');
    if (idx === -1) continue;
    const key = trimmed.slice(0, idx).trim();
    let val = trimmed.slice(idx + 1).trim();
    if (!key) continue;
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (process.env[key] == null || process.env[key] === '') {
      process.env[key] = val;
    }
  }
  return { loaded: true, filePath };
}

module.exports = { loadDotEnv };
