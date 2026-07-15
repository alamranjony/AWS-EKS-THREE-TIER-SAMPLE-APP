// Minimal smoke test - no external test framework required.
// Boots the app on an ephemeral port and hits both endpoints.
const http = require('http');

process.env.PORT = 0; // let OS assign a port
const app = require('./server');

function get(path, port) {
  return new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}${path}`, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    }).on('error', reject);
  });
}

const server = app.listen(0, async () => {
  const port = server.address().port;
  try {
    const root = await get('/', port);
    if (root.status !== 200 || !root.body.includes('Application is running')) {
      throw new Error('GET / failed');
    }

    const health = await get('/health', port);
    const parsed = JSON.parse(health.body);
    if (health.status !== 200 || parsed.status !== 'ok') {
      throw new Error('GET /health failed');
    }

    console.log('All backend tests passed');
    server.close(() => process.exit(0));
  } catch (err) {
    console.error('Test failed:', err.message);
    server.close(() => process.exit(1));
  }
});
