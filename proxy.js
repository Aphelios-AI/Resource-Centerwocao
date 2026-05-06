const http = require('http');
const https = require('https');

const PORT = 18888;
const TARGET_URL = 'https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions';

const server = http.createServer((req, res) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.method === 'POST') {
        let body = [];
        req.on('data', chunk => body.push(chunk));
        req.on('end', () => {
            const bodyStr = Buffer.concat(body).toString();
            console.log('Request body:', bodyStr);
            
            const parsedUrl = new URL(TARGET_URL);
            
            const options = {
                hostname: parsedUrl.hostname,
                port: 443,
                path: parsedUrl.pathname + parsedUrl.search,
                method: 'POST',
                headers: {
                    'Content-Type': req.headers['content-type'] || 'application/json',
                    'Authorization': req.headers['authorization']
                }
            };

            console.log('Proxying to:', parsedUrl.hostname);

            const proxyReq = https.request(options, proxyRes => {
                console.log('Response status:', proxyRes.statusCode);
                let proxyBody = [];
                proxyRes.on('data', chunk => proxyBody.push(chunk));
                proxyRes.on('end', () => {
                    const proxyBodyStr = Buffer.concat(proxyBody).toString();
                    console.log('Response body:', proxyBodyStr);
                    res.writeHead(proxyRes.statusCode, proxyRes.headers);
                    res.end(proxyBodyStr);
                });
            });

            proxyReq.on('error', err => {
                console.error('Proxy error:', err.message);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            });

            proxyReq.write(bodyStr);
            proxyReq.end();
        });
    } else {
        res.writeHead(405);
        res.end();
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Proxy server running at http://0.0.0.0:${PORT}`);
});
