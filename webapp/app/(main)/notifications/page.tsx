'use client';

import { useEffect, useState, useCallback } from 'react';
import { Bell, Trash2, BellOff } from 'lucide-react';
import { NotificationItem } from '@/types';
import {
  getAllNotifications,
  clearNotifications,
  addNotification,
} from '@/services/notificationStorageService';
import { onForegroundMessage } from '@/services/messagingService';
import toast from 'react-hot-toast';

export default function NotificationsPage() {
  const [items, setItems] = useState<NotificationItem[]>([]);

  const reload = useCallback(() => setItems(getAllNotifications()), []);

  useEffect(() => {
    reload();

    // Listen for foreground FCM messages
    let cleanup: (() => void) | null = null;
    onForegroundMessage((item) => {
      addNotification(item);
      reload();
      toast(item.title, { icon: '🔔' });
    }).then((unsub) => {
      cleanup = unsub;
    });

    return () => {
      cleanup?.();
    };
  }, [reload]);

  function handleClear() {
    clearNotifications();
    reload();
    toast.success('Notifications cleared');
  }

  function formatTime(iso: string) {
    try {
      return new Intl.DateTimeFormat('en-IN', {
        dateStyle: 'medium',
        timeStyle: 'short',
      }).format(new Date(iso));
    } catch {
      return iso;
    }
  }

  return (
    <div className="flex flex-col gap-4 max-w-2xl mx-auto">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Bell size={20} className="text-accent" /> Notifications
        </h1>
        {items.length > 0 && (
          <button
            onClick={handleClear}
            className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-destructive transition-colors"
          >
            <Trash2 size={16} /> Clear all
          </button>
        )}
      </div>

      {items.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-3 py-20 text-muted-foreground">
          <BellOff size={48} strokeWidth={1.2} />
          <p className="text-sm">No notifications yet</p>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {items.map((item, i) => (
            <div
              key={i}
              className="bg-card border border-border rounded-xl p-4 flex flex-col gap-1"
            >
              <p className="text-sm font-semibold">{item.title}</p>
              {item.body && (
                <p className="text-sm text-muted-foreground">{item.body}</p>
              )}
              <p className="text-xs text-muted-foreground/70 mt-1">
                {formatTime(item.timestamp)}
              </p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
