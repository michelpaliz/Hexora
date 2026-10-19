// One-time cleanup worker used when Hexora is deployed without offline caching.
// It immediately replaces the legacy Flutter worker and removes only the
// caches created by Flutter's former offline-first strategy.
const FLUTTER_CACHES = [
  'flutter-app-cache',
  'flutter-temp-cache',
  'flutter-app-manifest',
];

self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    await Promise.all(FLUTTER_CACHES.map((name) => caches.delete(name)));
    await self.clients.claim();
    await self.registration.unregister();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
