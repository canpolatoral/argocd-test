const http = require('http');

const port = process.env.PORT || 8080;
const message = process.env.GREETING || 'Hello, World!';

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
    return;
  }

  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end(`${message}\n`);
});

server.listen(port, () => {
  console.log(`hello-world listening on port ${port} 2`);
});
