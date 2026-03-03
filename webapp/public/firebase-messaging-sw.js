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
      self.registration.showNotification(title, {
        body,
        icon: '/logo.jpg',
      });
    });
  } catch (err) {
    console.error('Firebase messaging SW init failed:', err);
  }
}

initFirebase();
