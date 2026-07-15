const express = require('express');
const http = require('http');

const app = express();
const PORT = process.env.PORT || 3000;

// In docker-compose this resolves to the backend container by service name.
// In Kubernetes this resolves via the backend ClusterIP Service DNS name.
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http
      .get(url, (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(data) });
          } catch (e) {
            resolve({ status: res.statusCode, body: data });
          }
        });
      })
      .on('error', reject);
  });
}

app.get('/', async (req, res) => {
  let backendStatus = 'unreachable';
  let backendInfo = null;
  try {
    const health = await fetchJson(`${BACKEND_URL}/health`);
    backendStatus = health.body.status || 'unknown';
    const info = await fetchJson(`${BACKEND_URL}/api/info`);
    backendInfo = info.body;
  } catch (err) {
    backendStatus = `error: ${err.message}`;
  }

  res.status(200).send(`
    <html>
      <head><title>DevOps Assessment Frontend</title></head>
      <body style="font-family: sans-serif; margin: 40px;">
        <h1>Frontend is running</h1>
        <p>Backend health: <strong>${backendStatus}</strong></p>
        <pre>${JSON.stringify(backendInfo, null, 2)}</pre>
      </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Frontend listening on port ${PORT}, backend at ${BACKEND_URL}`);
});

module.exports = app;
