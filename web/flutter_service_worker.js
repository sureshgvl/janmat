'use strict';
// Auto-update Service Worker for Flutter Web

const CACHE_NAME = 'app-cache-v1';
const RESOURCES = {}; // Flutter will inject resources here

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(async function () {
    try {
      const cache = await caches.open(CACHE_NAME);
      await cache.keys().then(keys => {
        keys.forEach(key => cache.delete(key));
      });
      await clients.claim();
    } catch (err) {
      console.error('Service worker activation failed:', err);
    }
  }());
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;

  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      try {
        const networkResponse = await fetch(event.request);
        cache.put(event.request, networkResponse.clone());
        return networkResponse;
      } catch (e) {
        const cachedResponse = await cache.match(event.request);
        return cachedResponse || Response.error();
      }
    })()
  );
});
