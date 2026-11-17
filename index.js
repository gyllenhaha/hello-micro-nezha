const express = require('express');
const app = express();
const PORT = process.env.PORT || 5000;

app.get('/', (req, res) => {
  res.send('Hello World! - hello-micro with Nezha probe');
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', app: 'hello-micro-nezha', port: PORT });
});

app.listen(PORT, () => {
  console.log(`Node app is running at localhost:${PORT}`);
});
