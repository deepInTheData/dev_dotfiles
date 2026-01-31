const https = require('https');
const crypto = require('crypto');
const { URL } = require('url');

function sha256Hex(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}

function hmac(key, str, encoding) {
  return crypto.createHmac('sha256', key).update(str, 'utf8').digest(encoding);
}

function iso8601Basic(d) {
  const pad = (n) => String(n).padStart(2, '0');
  return (
    d.getUTCFullYear() +
    pad(d.getUTCMonth() + 1) +
    pad(d.getUTCDate()) +
    'T' +
    pad(d.getUTCHours()) +
    pad(d.getUTCMinutes()) +
    pad(d.getUTCSeconds()) +
    'Z'
  );
}

function signKey(secret, dateStamp, region, service) {
  const kDate = hmac('AWS4' + secret, dateStamp);
  const kRegion = hmac(kDate, region);
  const kService = hmac(kRegion, service);
  return hmac(kService, 'aws4_request');
}

function request(opts, bodyBuf) {
  return new Promise((resolve, reject) => {
    const req = https.request(opts, (res) => {
      const chunks = [];
      res.on('data', (c) => chunks.push(c));
      res.on('end', () => {
        const text = Buffer.concat(chunks).toString('utf8');
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ statusCode: res.statusCode, headers: res.headers, text });
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${text}`));
        }
      });
    });
    req.on('error', reject);
    req.write(bodyBuf);
    req.end();
  });
}

async function putObject({
  endpoint,
  bucket,
  key,
  body,
  contentType,
  cacheControl,
  accessKeyId,
  secretAccessKey,
  region = 'auto'
}) {
  const url = new URL(endpoint);
  const host = url.host;
  const method = 'PUT';
  const service = 's3';

  // path-style: /<bucket>/<key>
  const encodedKey = key.split('/').map(encodeURIComponent).join('/');
  const canonicalUri = `/${bucket}/${encodedKey}`;
  const canonicalQuery = '';

  const now = new Date();
  const amzDate = iso8601Basic(now);
  const dateStamp = amzDate.slice(0, 8);

  const payloadHash = sha256Hex(body);

  const headers = {
    host,
    'content-type': contentType || 'application/octet-stream',
    'content-length': String(body.length),
    'x-amz-content-sha256': payloadHash,
    'x-amz-date': amzDate
  };
  if (cacheControl) headers['cache-control'] = cacheControl;

  const signedHeaders = Object.keys(headers)
    .map((h) => h.toLowerCase())
    .sort()
    .join(';');

  const canonicalHeaders = Object.keys(headers)
    .map((h) => h.toLowerCase())
    .sort()
    .map((h) => `${h}:${String(headers[h]).trim()}\n`)
    .join('');

  const canonicalRequest = [
    method,
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    signedHeaders,
    payloadHash
  ].join('\n');

  const algorithm = 'AWS4-HMAC-SHA256';
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const stringToSign = [
    algorithm,
    amzDate,
    credentialScope,
    sha256Hex(Buffer.from(canonicalRequest, 'utf8'))
  ].join('\n');

  const signingKey = signKey(secretAccessKey, dateStamp, region, service);
  const signature = hmac(signingKey, stringToSign, 'hex');

  const authorization = `${algorithm} Credential=${accessKeyId}/${credentialScope}, SignedHeaders=${signedHeaders}, Signature=${signature}`;

  const reqOpts = {
    method,
    hostname: host,
    path: canonicalUri,
    headers: {
      ...headers,
      Authorization: authorization
    }
  };

  return request(reqOpts, body);
}

module.exports = { putObject };
