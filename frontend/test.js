const http = require('http');

process.env.PORT = 0;
const app = require('./server');

function get(path, port) {
  return new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}${path}`, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve({ status: res.statusCode, body: data }));
    }).on('error', reject);
  });
}

const server = app.listen(0, async () => {
  const port = server.address().port;
  try {
    const health = await get('/health', port);
    if (health.status !== 200) throw new Error('GET /health failed');
    console.log('All frontend tests passed');
    server.close(() => process.exit(0));
  } catch (err) {
    console.error('Test failed:', err.message);
    server.close(() => process.exit(1));
  }
});
