// @ts-nocheck
const CACHE = 'wc2026-v1';
const ASSETS = [
  '/fifa/',
  '/fifa/index.html',
  '/fifa/assets/react.min.js',
  '/fifa/assets/react-dom.min.js',
  '/fifa/icons/icon-192.png',
  '/fifa/icons/icon-512.png',
  '/fifa/icons/icon-180.png'
];

// Install: cache all static assets
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

// Activate: remove old caches
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    ).then(() => self.clients.claim())
  );
});

// Fetch: network-first for HTML (always get latest), cache-first for assets
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // Always pass through to network: ESPN API, Google Analytics, third-party scripts
  if (url.hostname.includes('espn.com')) return;
  if (url.hostname.includes('google-analytics.com')) return;
  if (url.hostname.includes('googletagmanager.com')) return;
  if (url.hostname.includes('doubleclick.net')) return;

  // HTML: network first, fall back to cache
  if (e.request.destination === 'document' || url.pathname.endsWith('.html') || url.pathname.endsWith('/')) {
    e.respondWith(
      fetch(e.request)
        .then(res => { caches.open(CACHE).then(c => c.put(e.request, res.clone())); return res; })
        .catch(() => caches.match(e.request))
    );
    return;
  }

  // Assets (JS, images): cache first
  e.respondWith(
    caches.match(e.request).then(cached => cached || fetch(e.request))
  );
});
