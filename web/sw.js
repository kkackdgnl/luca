self.addEventListener('install', (e) => {
  e.waitUntil(caches.open('jarvis-v1').then(c => c.addAll([
    './', './index.html', './manifest.webmanifest',
    './icons/icon-192.png', './icons/icon-512.png'
  ])));
});
self.addEventListener('fetch', (e) => {
  e.respondWith(caches.match(e.request).then(res => res || fetch(e.request)));
});
