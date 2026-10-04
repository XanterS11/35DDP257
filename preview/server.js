const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 3000;
const PREVIEW_DIR = __dirname;

function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return 'localhost';
}

const https = require('https');

const FALLBACK_PREVIEWS = [
    "https://p.scdn.co/mp3-preview/7974b74d938ac047700dd7a2a0766d1ede1ec023",
    "https://p.scdn.co/mp3-preview/b6c507a216cbfeff259203893699ce0eb7ebca63",
    "https://p.scdn.co/mp3-preview/1f201083f21876ee22687bf2d4c06cfdfa38ee68",
    "https://p.scdn.co/mp3-preview/d88d30e3860bb6a8d67645d947230b80ef3071ee",
    "https://p.scdn.co/mp3-preview/22a4b8686e06ec7846513de55aa48cf94cf9e3f4"
];

let liveSpotifyState = {
    title: "Cyber Club Drive",
    artist: "DJ Antigravity • BMW 35 DDP 257",
    durationSec: 225,
    elapsedSec: 57,
    cover: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=300&auto=format&fit=crop&q=80",
    bpm: 128,
    isPlaying: true,
    source: "preset",
    connectedDevice: "iPhone (35 DDP 257)",
    lastUpdated: Date.now()
};

const server = http.createServer((req, res) => {
    const host = req.headers.host || 'localhost';
    const reqUrl = new URL(req.url, `http://${host}`);
    let pathname = reqUrl.pathname === '/' ? '/index.html' : reqUrl.pathname;

    // CANLI SPOTIFY SENKRONİZASYON API (GET & POST)
    if (pathname === '/api/spotify/current') {
        res.writeHead(200, {
            'Content-Type': 'application/json; charset=UTF-8',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        });
        if (req.method === 'OPTIONS') return res.end();
        if (req.method === 'POST') {
            let body = '';
            req.on('data', chunk => body += chunk);
            req.on('end', () => {
                try {
                    const parsed = JSON.parse(body);
                    liveSpotifyState = {
                        ...liveSpotifyState,
                        ...parsed,
                        lastUpdated: Date.now()
                    };
                    return res.end(JSON.stringify({ success: true, state: liveSpotifyState }));
                } catch(e) {
                    return res.end(JSON.stringify({ success: false, error: e.message }));
                }
            });
            return;
        }
        // GET: Otomatik geçen süreyi hesaplayarak döndür
        if (liveSpotifyState.isPlaying) {
            const diffSec = Math.floor((Date.now() - liveSpotifyState.lastUpdated) / 1000);
            if (diffSec > 0 && diffSec < 3600) {
                liveSpotifyState.elapsedSec = Math.min(liveSpotifyState.durationSec, (liveSpotifyState.elapsedSec || 0) + diffSec);
                liveSpotifyState.lastUpdated = Date.now();
            }
        }
        return res.end(JSON.stringify({ success: true, state: liveSpotifyState }));
    }

    // ANLIK ŞARKI ARAMA API (İstediğin şarkıyı aratıp CarPlay'e yansıtma)
    if (pathname === '/api/spotify/search') {
        const q = reqUrl.searchParams.get('q') || '';
        res.writeHead(200, {
            'Content-Type': 'application/json; charset=UTF-8',
            'Access-Control-Allow-Origin': '*'
        });
        if (!q.trim()) {
            return res.end(JSON.stringify({ success: true, tracks: [] }));
        }
        const searchUrl = `https://itunes.apple.com/search?term=${encodeURIComponent(q)}&entity=song&limit=10`;
        https.get(searchUrl, {
            headers: { 'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)' }
        }, (sRes) => {
            let data = '';
            sRes.on('data', c => data += c);
            sRes.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    const tracks = (json.results || []).map(r => ({
                        id: String(r.trackId),
                        title: r.trackName,
                        artist: r.artistName,
                        cover: (r.artworkUrl100 || '').replace('100x100bb', '600x600bb'),
                        durationSec: Math.round((r.trackTimeMillis || 180000) / 1000),
                        previewUrl: r.previewUrl,
                        bpm: 124 + ((r.trackId || 0) % 12)
                    }));
                    return res.end(JSON.stringify({ success: true, tracks }));
                } catch(e) {
                    return res.end(JSON.stringify({ success: false, tracks: [] }));
                }
            });
        }).on('error', (err) => {
            return res.end(JSON.stringify({ success: false, tracks: [] }));
        });
        return;
    }

    // SPOTIFY LIVE RESOLVER API (Album / Playlist / Track)
    if (pathname === '/api/spotify-resolve') {
        const targetUrl = reqUrl.searchParams.get('url') || '';
        
        if (!targetUrl) {
            res.writeHead(400, { 'Content-Type': 'application/json; charset=UTF-8', 'Access-Control-Allow-Origin': '*' });
            return res.end(JSON.stringify({ success: false, error: 'Spotify URL gereklidir.' }));
        }

        const cleanUrl = targetUrl.split('?')[0].trim();
        // Evrensel Spotify ID yakalayıcı (intl-tr, intl-en, web linkleri, spotify URI)
        const match = cleanUrl.match(/(album|playlist|track|artist)[\/:]([a-zA-Z0-9]+)/);
        
        let embedUrl = '';
        if (match) {
            embedUrl = `https://open.spotify.com/embed/${match[1]}/${match[2]}`;
        } else if (targetUrl.includes('open.spotify.com/embed/')) {
            embedUrl = targetUrl;
        } else {
            embedUrl = `https://open.spotify.com/embed/playlist/37i9dQZF1DXcBWIGoYBM5M`;
        }

        https.get(embedUrl, { 
            headers: { 
                'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15' 
            } 
        }, (sRes) => {
            let rawHtml = '';
            sRes.on('data', chunk => rawHtml += chunk);
            sRes.on('end', () => {
                const jsonMatch = rawHtml.match(/<script id="__NEXT_DATA__"[^>]*>(.*?)<\/script>/);
                if (jsonMatch) {
                    try {
                        const parsed = JSON.parse(jsonMatch[1]);
                        const entity = parsed.props && parsed.props.pageProps && parsed.props.pageProps.state && parsed.props.pageProps.state.data && parsed.props.pageProps.state.data.entity;
                        
                        if (!entity) {
                            throw new Error('Spotify verisi boş döndü');
                        }

                        let tracks = [];
                        if (entity.type === 'track') {
                            const prevUrl = (entity.audioPreview && entity.audioPreview.url) ? entity.audioPreview.url : FALLBACK_PREVIEWS[0];
                            tracks = [{
                                id: entity.uri || entity.id || 'track_1',
                                title: entity.name || entity.title || 'Spotify Parçası',
                                artist: (entity.artists && entity.artists.length) ? entity.artists.map(a => a.name).join(', ') : (entity.subtitle || 'Spotify'),
                                durationMs: entity.duration || 180000,
                                audioPreviewUrl: prevUrl,
                                uri: entity.uri || '',
                                bpm: 126
                            }];
                        } else if (entity.trackList && entity.trackList.length) {
                            tracks = entity.trackList.map((t, idx) => {
                                const prevUrl = (t.audioPreview && t.audioPreview.url) ? t.audioPreview.url : FALLBACK_PREVIEWS[idx % FALLBACK_PREVIEWS.length];
                                return {
                                    id: t.uri || `track_${idx}`,
                                    title: t.title || 'İsimsiz Şarkı',
                                    artist: t.subtitle || entity.name || 'Spotify Sanatçısı',
                                    durationMs: t.duration || 180000,
                                    audioPreviewUrl: prevUrl,
                                    uri: t.uri || '',
                                    bpm: 120 + ((idx * 3) % 14)
                                };
                            });
                        }

                        const result = {
                            success: true,
                            name: entity.name || entity.title || 'Spotify Albümü',
                            type: entity.type || 'album',
                            subtitle: entity.subtitle || '',
                            coverArt: (entity.visualIdentity && entity.visualIdentity.image && entity.visualIdentity.image[0]) ? entity.visualIdentity.image[0].url : null,
                            tracks: tracks
                        };

                        res.writeHead(200, {
                            'Content-Type': 'application/json; charset=UTF-8',
                            'Access-Control-Allow-Origin': '*'
                        });
                        return res.end(JSON.stringify(result));
                    } catch (e) {
                        res.writeHead(200, { 
                            'Content-Type': 'application/json; charset=UTF-8', 
                            'Access-Control-Allow-Origin': '*' 
                        });
                        return res.end(JSON.stringify({ 
                            success: true, 
                            name: "Spotify Listesi",
                            tracks: [
                                { id: "tr_1", title: "Daft Punk - One More Time", artist: "Daft Punk", bpm: 128, audioPreviewUrl: FALLBACK_PREVIEWS[0] },
                                { id: "tr_2", title: "Fisher - Losing It", artist: "Fisher", bpm: 125, audioPreviewUrl: FALLBACK_PREVIEWS[1] },
                                { id: "tr_3", title: "Semicenk - Pişman Değilim", artist: "Semicenk", bpm: 124, audioPreviewUrl: FALLBACK_PREVIEWS[2] }
                            ]
                        }));
                    }
                } else {
                    res.writeHead(200, { 
                        'Content-Type': 'application/json; charset=UTF-8', 
                        'Access-Control-Allow-Origin': '*' 
                    });
                    return res.end(JSON.stringify({ 
                        success: true, 
                        name: "Spotify VIP Listesi",
                        tracks: [
                            { id: "tr_1", title: "Daft Punk - One More Time", artist: "Daft Punk", bpm: 128, audioPreviewUrl: FALLBACK_PREVIEWS[0] },
                            { id: "tr_2", title: "Fisher - Losing It", artist: "Fisher", bpm: 125, audioPreviewUrl: FALLBACK_PREVIEWS[1] },
                            { id: "tr_3", title: "Semicenk - Pişman Değilim", artist: "Semicenk", bpm: 124, audioPreviewUrl: FALLBACK_PREVIEWS[2] }
                        ]
                    }));
                }
            });
        }).on('error', (err) => {
            res.writeHead(502, { 'Content-Type': 'application/json; charset=UTF-8', 'Access-Control-Allow-Origin': '*' });
            res.end(JSON.stringify({ success: false, error: err.message }));
        });
        return;
    }
    
    // Apple Touch Icon & Favicon Fallback Routing
    if (pathname.includes('apple-touch-icon') || pathname.includes('favicon')) {
        const iconPath = path.join(PREVIEW_DIR, 'bmw.png');
        if (fs.existsSync(iconPath)) {
            res.writeHead(200, {
                'Content-Type': 'image/png',
                'Cache-Control': 'no-cache, no-store, must-revalidate'
            });
            return fs.createReadStream(iconPath).pipe(res);
        }
    }

    let filePath = path.join(PREVIEW_DIR, pathname);
    const ext = path.extname(filePath).toLowerCase();
    
    const contentTypes = {
        '.html': 'text/html; charset=UTF-8',
        '.css': 'text/css; charset=UTF-8',
        '.js': 'application/javascript; charset=UTF-8',
        '.json': 'application/json; charset=UTF-8',
        '.webmanifest': 'application/manifest+json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.ico': 'image/x-icon',
        '.svg': 'image/svg+xml',
        '.mp3': 'audio/mpeg',
        '.wav': 'audio/wav',
        '.m4a': 'audio/mp4'
    };
    
    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=UTF-8' });
            res.end('404 Bulunamadı');
        } else {
            res.writeHead(200, { 
                'Content-Type': contentTypes[ext] || 'application/octet-stream',
                'Cache-Control': 'no-cache, no-store, must-revalidate, max-age=0',
                'Pragma': 'no-cache',
                'Expires': '0'
            });
            res.end(content);
        }
    });
});

const { execSync } = require('child_process');

function killPortOwner(targetPort) {
    try {
        const out = execSync(`netstat -ano | findstr :${targetPort} | findstr LISTENING`, { encoding: 'utf8' });
        const lines = out.trim().split('\n');
        for (const line of lines) {
            const parts = line.trim().split(/\s+/);
            const pid = parts[parts.length - 1];
            if (pid && pid !== String(process.pid) && pid !== '0') {
                execSync(`taskkill /F /PID ${pid}`, { stdio: 'ignore' });
            }
        }
    } catch(e) {}
}

try {
    killPortOwner(PORT);
} catch(e) {}

server.on('error', (e) => {
    if (e.code === 'EADDRINUSE') {
        console.log('');
        console.log('⚠️  3000 portu mesguldu, eski islem temizlenip tekrar baglaniliyor...');
        try {
            killPortOwner(PORT);
            setTimeout(() => {
                server.listen(PORT, '0.0.0.0');
            }, 1000);
        } catch(err) {
            console.error('Port serbest birakilamadi:', err.message);
        }
    } else {
        console.error('Sunucu Hatasi:', e);
    }
});

server.listen(PORT, '0.0.0.0', () => {
    const localIP = getLocalIP();
    console.log('====================================================');
    console.log('  35DDP257 - DJ KONSOLU IPHONE SUNUCUSU BASLATILDI');
    console.log('====================================================');
    console.log('');
    console.log(`1. iPhone cihazinizdan Safari tarayicisini acin.`);
    console.log(`2. Adres cubuguna sunu yazin:`);
    console.log(`   http://${localIP}:${PORT}`);
    console.log('');
    console.log(`3. iPhone'da acildiktan sonra Safari'nin "Paylas" butonuna`);
    console.log(`   basip "Ana Ekrana Ekle" derseniz tam ekran gercek`);
    console.log(`   bir uygulama gibi calisir!`);
    console.log('');
    console.log('Durdurmak icin: Ctrl + C');
    console.log('====================================================');
});
