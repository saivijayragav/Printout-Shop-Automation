'use client';

import { useEffect } from 'react';
import { fetchSettings } from '@/services/settingsService';
import { useAppStore } from '@/store/appStore';

/**
 * Invisible client component mounted in the root layout.
 * Initialises Firebase-dependent settings on app boot.
 */
export default function FirebaseInit() {
  const setLiveOrdersEnabled = useAppStore((s) => s.setLiveOrdersEnabled);
  const setSession = useAppStore((s) => s.setSession);

  useEffect(() => {
    // Load settings from Firestore
    fetchSettings().then(({ liveOrdersEnabled }) => {
      setLiveOrdersEnabled(liveOrdersEnabled);
    });

    // Restore session from localStorage
    try {
      const name = localStorage.getItem('userName') ?? '';
      const phone = localStorage.getItem('userPhone') ?? '';
      const isLoggedIn = localStorage.getItem('isLoggedIn') === 'true';
      if (isLoggedIn && name && phone) {
        setSession({ name, phone, isLoggedIn });
      }
    } catch {
      // localStorage unavailable (SSR or private browsing)
    }
  }, [setLiveOrdersEnabled, setSession]);

  return null;
}
