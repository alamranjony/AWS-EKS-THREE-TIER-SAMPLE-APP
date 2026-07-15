const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;

// DB config read from env vars injected via a Kubernetes Secret that is
// itself synced from AWS Secrets Manager - see
// k8s/backend-secret-example.yaml and docs/secrets-manager-integration.md.
// Points at an RDS MySQL instance reachable only from inside the VPC's
// private subnets - never a public endpoint.
const dbConfig = {
  host: process.env.DB_HOST || 'not-configured',
  name: process.env.DB_NAME || 'not-configured',
  user: process.env.DB_USER || 'not-configured',
  // DB_PASSWORD is intentionally never logged or exposed via any endpoint
};

app.get('/', (req, res) => {
  res.status(200).send('Application is running');
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Simple info endpoint the frontend calls to prove frontend -> backend
// connectivity works. Does not expose secrets.
app.get('/api/info', (req, res) => {
  res.status(200).json({
    service: 'backend',
    dbHost: dbConfig.host,
    message: process.env.API_MESSAGE || 'Hello from backend',
    timestamp: new Date().toISOString(),
  });
});

app.listen(PORT, () => {
  console.log(`Backend listening on port ${PORT}`);
});

module.exports = app;
