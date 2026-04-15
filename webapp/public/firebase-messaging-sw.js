// Firebase Cloud Messaging Service Worker
// Required for background push notifications on web.
// This file must be hosted at /firebase-messaging-sw.js (public root).

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

async function initFirebase() {
  try {
    const configUrl = `${self.location.origin}/api/firebase-config`;
    const response = await fetch(configUrl, { cache: 'no-store' });
    if (!response.ok) {
      throw new Error(`Firebase config load failed: ${response.status}`);
    }

    const config = await response.json();
    firebase.initializeApp(config);
    const messaging = firebase.messaging();

    // Handle background messages (when the tab is not in focus)
    messaging.onBackgroundMessage((payload) => {
      const title = payload.notification?.title ?? 'RIT Arcade';
      const body = payload.notification?.body ?? '';
      
      const notificationOptions = {
        body,
        icon: '/logo.jpg',
        data: payload.data, // Need to pass data so the click handler has access to it
      };

      self.registration.showNotification(title, notificationOptions);
    });
  } catch (err) {
    console.error('Firebase messaging SW init failed:', err);
  }
}

// Handle Notification Clicks to open the Web App
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  const urlToOpen = new URL('/history', self.location.origin).href;

  event.waitUntil(
    self.clients.matchAll({
      type: 'window',
      includeUncontrolled: true
    }).then((windowClients) => {
      // Check if there is already a window/tab open with the target URL
      for (let i = 0; i < windowClients.length; i++) {
        let client = windowClients[i];
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      // If no window/tab is open, open one
      if (self.clients.openWindow) {
        return self.clients.openWindow(urlToOpen);
      }
    })
  );
});

initFirebase();
