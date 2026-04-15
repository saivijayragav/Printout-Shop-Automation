import { Payment } from '@/types';

const STORAGE_KEY = 'payment_history';

/** Reads all stored payments from localStorage */
export function getAllPayments(): Payment[] {
  if (typeof window === 'undefined') return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as Payment[]) : [];
  } catch {
    return [];
  }
}

/** Inserts a new payment record */
export function insertPayment(payment: Payment): void {
  const existing = getAllPayments();
  existing.unshift(payment); // newest first
  localStorage.setItem(STORAGE_KEY, JSON.stringify(existing));
}

/** Deletes a payment by its id */
export function deletePaymentById(id: string): void {
  const filtered = getAllPayments().filter((p) => p.id !== id);
  localStorage.setItem(STORAGE_KEY, JSON.stringify(filtered));
}

/** Deletes multiple payments by ids */
export function deletePaymentsByIds(ids: string[]): void {
  const filtered = getAllPayments().filter((p) => !ids.includes(p.id));
  localStorage.setItem(STORAGE_KEY, JSON.stringify(filtered));
}

/** Clears all payment history */
export function clearPayments(): void {
  localStorage.removeItem(STORAGE_KEY);
}
