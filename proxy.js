const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = 18888;
const STATIC_DIR = __dirname;
const TARGET_URL = 'https://ark.cn-beijing.volces.com/api/coding/v3/chat/completions';
const MAX_BODY_SIZE = 5 * 1024 * 1024;
const RATE_LIMIT_WINDOW = 60 * 1000;
const RATE_LIMIT_MAX = 30;

var MIME = {
    '.html': 'text/html; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.txt': 'text/plain; charset=utf-8',
    '.pdf': 'application/pdf'
};

var rateMap = {};

setInterval(function () {
    var now = Date.now();
    Object.keys(rateMap).forEach(function (ip) {
        if (now - rateMap[ip].start > RATE_LIMIT_WINDOW) {
            delete rateMap[ip];
        }
    });
}, 60 * 1000);

function getClientIP(req) {
    return req.headers['x-forwarded-for'] || req.connection.remoteAddress || 'unknown';
}

function checkRate(ip) {
    var now = Date.now();
    if (!rateMap[ip] || now - rateMap[ip].start > RATE_LIMIT_WINDOW) {
        rateMap[ip] = { count: 0, start: now };
    }
    rateMap[ip].count++;
    return rateMap[ip].count <= RATE_LIMIT_MAX;
}

function serveStatic(req, res) {
    var urlPath = req.url.split('?')[0];
    if (urlPath === '/') urlPath = '/index.html';

    var filePath = path.join(STATIC_DIR, decodeURIComponent(urlPath));
    var normalized = path.normalize(filePath);

    if (normalized.indexOf(path.normalize(STATIC_DIR)) !== 0) {
        res.writeHead(403);
        res.end('Forbidden');
        return true;
    }

    if (!fs.existsSync(normalized) || fs.statSync(normalized).isDirectory()) {
        return false;
    }

    var ext = path.extname(normalized).toLowerCase();
    var contentType = MIME[ext] || 'application/octet-stream';

    res.writeHead(200, { 'Content-Type': contentType });
    fs.createReadStream(normalized).pipe(res);
    return true;
}

var server = http.createServer(function (req, res) {
    var clientIP = getClientIP(req);
    console.log('[' + new Date().toISOString() + '] ' + req.method + ' ' + req.url + ' from ' + clientIP);

    var origin = req.headers.origin || '';
    var originHost = origin.replace(/^https?:\/\//, '').split(':')[0];
    var isLocalOrigin = originHost === 'localhost' ||
        originHost === '127.0.0.1' ||
        /^192\.168\./.test(originHost) ||
        /^10\./.test(originHost) ||
        /^172\.(1[6-9]|2\d|3[01])\./.test(originHost);
    res.setHeader('Access-Control-Allow-Origin', isLocalOrigin ? origin : 'http://localhost');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    if (req.method === 'GET') {
        if (serveStatic(req, res)) return;
        res.writeHead(404);
        res.end('Not Found');
        return;
    }

    if (req.method !== 'POST') {
        res.writeHead(405);
        res.end();
        return;
    }

    if (!checkRate(clientIP)) {
        console.log('Rate limit exceeded for ' + clientIP);
        res.writeHead(429, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: '\u8bf7\u6c42\u8fc7\u4e8e\u9891\u7e41\uff0c\u8bf7\u7a0d\u540e\u518d\u8bd5' }));
        return;
    }

    var body = [];
    var bodySize = 0;
    var aborted = false;

    req.on('data', function (chunk) {
        bodySize += chunk.length;
        if (bodySize > MAX_BODY_SIZE) {
            aborted = true;
            req.destroy();
            res.writeHead(413, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ error: '\u8bf7\u6c42\u4f53\u8fc7\u5927' }));
            return;
        }
        body.push(chunk);
    });

    req.on('end', function () {
        if (aborted) return;

        var bodyStr = Buffer.concat(body).toString();

        var parsedUrl = new URL(TARGET_URL);

        var options = {
            hostname: parsedUrl.hostname,
            port: 443,
            path: parsedUrl.pathname + parsedUrl.search,
            method: 'POST',
            headers: {
                'Content-Type': req.headers['content-type'] || 'application/json',
                'Authorization': req.headers['authorization']
            }
        };

        var proxyReq = https.request(options, function (proxyRes) {
            res.writeHead(proxyRes.statusCode, proxyRes.headers);
            proxyRes.pipe(res);
        });

        proxyReq.on('error', function (err) {
            console.error('Proxy error: ' + err.message);
            if (!res.headersSent) {
                res.writeHead(502, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: '\u540e\u7aef\u670d\u52a1\u4e0d\u53ef\u8fbe' }));
            }
        });

        proxyReq.write(bodyStr);
        proxyReq.end();
    });
});

server.listen(PORT, '0.0.0.0', function () {
    console.log('Server running at http://0.0.0.0:' + PORT);
    console.log('Static files: ' + STATIC_DIR);
    console.log('Rate limit: ' + RATE_LIMIT_MAX + ' requests per ' + (RATE_LIMIT_WINDOW / 1000) + 's');
    console.log('Max body size: ' + (MAX_BODY_SIZE / 1024 / 1024) + 'MB');
});
