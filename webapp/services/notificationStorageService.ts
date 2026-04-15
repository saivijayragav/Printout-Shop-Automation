import { NotificationItem } from '@/types';

const STORAGE_KEY = 'notification_history';

export function getAllNotifications(): NotificationItem[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as NotificationItem[]) : [];
  } catch {
    return [];
  }
}

export function addNotification(item: NotificationItem): void {
  const existing = getAllNotifications();
  existing.unshift(item); // newest first
  localStorage.setItem(STORAGE_KEY, JSON.stringify(existing));
}

export function clearNotifications(): void {
  localStorage.removeItem(STORAGE_KEY);
}
