const https = require('https');
const fs = require('fs');
const os = require('os');
const path = require('path');
const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const token = cfg.tokens?.access_token;
const project = 'tuition-attendance-9a2b1';
function request(method, url, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const u = new URL(url);
    const opts = { method, headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' } };
    if (data) opts.headers['Content-Length'] = Buffer.byteLength(data);
    const req = https.request(u, opts, res => {
      let buf = '';
      res.on('data', chunk => buf += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(buf ? JSON.parse(buf) : null);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${buf}`));
        }
      });
    });
    req.on('error', reject);
    if (data) req.write(data);
    req.end();
  });
}
async function list(col) {
  const url = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents/${col}`;
  try {
    const res = await request('GET', url);
    console.log('===', col, '===');
    if (!res.documents) {
      console.log('No docs');
      return;
    }
    for (const doc of res.documents) {
      console.log(doc.name);
      if (doc.fields) console.log(JSON.stringify(doc.fields));
    }
  } catch (e) {
    console.error('ERR', col, e.message);
  }
}
(async () => {
  await list('institutions');
  await list('branches');
  await list('institutionInvites');
  await list('teacherInvites');
  await list('teachers');
  await list('students');
})();
