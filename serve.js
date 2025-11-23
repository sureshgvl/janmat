const http = require('http');
const fs = require('fs');
const path = require('path');

const server = http.createServer((req, res) => {
  let filePath = path.join(__dirname, 'build/web');

  // SPA routing: serve index.html for all non-asset routes
  if (req.url === '/' || req.url.startsWith('/candidate/')) {
    filePath = path.join(filePath, 'index.html');
  } else {
    filePath = path.join(filePath, req.url);
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('File not found');
      return;
    }

    const ext = path.extname(filePath);
    const contentType = {
      '.html': 'text/html',
      '.js': 'text/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.ico': 'image/x-icon',
      '.svg': 'image/svg+xml',
      '.woff': 'font/woff',
      '.woff2': 'font/woff2'
    }[ext] || 'text/plain';

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
});

const port = 8080;
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
