const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Flask backend URL — override via env var for different deployment scenarios
const FLASK_URL = process.env.FLASK_URL || 'http://localhost:5000';

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Proxy API calls to Flask backend
app.get('/api/data', async (req, res) => {
  try {
    const response = await axios.get(`${FLASK_URL}/api/data`);
    res.json(response.data);
  } catch (err) {
    res.status(500).json({ error: 'Failed to reach Flask backend', detail: err.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'express-frontend' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Express frontend running on port ${PORT}`);
  console.log(`Connecting to Flask at: ${FLASK_URL}`);
});
