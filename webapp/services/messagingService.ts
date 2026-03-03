import { doc, setDoc } from 'firebase/firestore';
import { getToken, onMessage } from 'firebase/messaging';
import { db, getMessagingInstance } from '@/lib/firebase';
import { NotificationItem } from '@/types';

const VAPID_KEY = process.env.NEXT_PUBLIC_FCM_VAPID_KEY;

/**
 * Requests browser notification permission, retrieves the FCM token,
 * and saves it to Firestore users/{phone}.
 * Mirrors lib/services/firebase_messaging_service.dart
 */
export async function initializeMessaging(phone: string): Promise<void> {
  try {
    const messaging = await getMessagingInstance();
    if (!messaging) return;

    const permission = await Notification.requestPermission();
    if (permission !== 'granted') return;

    const token = await getToken(messaging, { vapidKey: VAPID_KEY });
    if (token) {
      await saveTokenForUser(phone, token);
    }
  } catch (err) {
    console.warn('FCM init failed:', err);
  }
}

/** Saves an FCM token to Firestore users/{phone} */
export async function saveTokenForUser(phone: string, token: string): Promise<void> {
  try {
    await setDoc(doc(db, 'users', phone), { fcmToken: token }, { merge: true });
  } catch (err) {
    console.warn('Failed to save FCM token:', err);
  }
}

/**
 * Registers a foreground message handler.
 * Returns an unsubscribe function.
 */
export async function onForegroundMessage(
  callback: (notification: NotificationItem) => void
): Promise<(() => void) | null> {
  const messaging = await getMessagingInstance();
  if (!messaging) return null;

  const unsub = onMessage(messaging, (payload) => {
    const item: NotificationItem = {
      title: payload.notification?.title ?? 'New notification',
      body: payload.notification?.body ?? '',
      timestamp: new Date().toISOString(),
    };
    callback(item);
  });

  return unsub;
}
