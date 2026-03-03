import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/lib/firebase';

/**
 * Reads settings/config from Firestore and returns relevant flags.
 * Mirrors lib/services/setting_service.dart
 */
export async function fetchSettings(): Promise<{ liveOrdersEnabled: boolean }> {
  try {
    const snap = await getDoc(doc(db, 'settings', 'config'));
    if (snap.exists()) {
      const data = snap.data();
      return { liveOrdersEnabled: data.liveOrdersEnabled ?? true };
    }
  } catch (err) {
    console.warn('Failed to load settings from Firestore:', err);
  }
  return { liveOrdersEnabled: true };
}
