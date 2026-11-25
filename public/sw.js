const CACHE_NAME = 'ful454-pwa-shell-v2';
const CORE = ['/', '/manifest.webmanifest', '/icons/icon.svg', '/icons/logo.svg'];
self.addEventListener('install', event => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    await Promise.all(CORE.map(async path => {
      try { const response = await fetch(path, { cache: 'reload' }); if (response.ok) await cache.put(path, response); } catch (_) {}
    }));
    await self.skipWaiting();
  })());
});
self.addEventListener('activate', event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => key.endsWith('-pwa-shell-v1') && key !== CACHE_NAME).map(key => caches.delete(key)));
    await self.clients.claim();
  })());
});
self.addEventListener('fetch', event => {
  const request = event.request;
  if (request.method !== 'GET' || new URL(request.url).origin !== self.location.origin) return;
  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const response = await fetch(request, { cache: 'no-store' });
        if (response.ok) { const cache = await caches.open(CACHE_NAME); await cache.put('/', response.clone()); }
        return response;
      } catch (_) {
        return (await caches.match('/')) || Response.error();
      }
    })());
    return;
  }
  const url = new URL(request.url);
  if (url.pathname === '/manifest.webmanifest' || url.pathname.startsWith('/icons/')) {
    event.respondWith((async () => (await caches.match(request)) || fetch(request))());
  }
});