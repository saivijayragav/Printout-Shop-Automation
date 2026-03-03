import {
  collection,
  addDoc,
  getAggregateFromServer,
  count,
  sum,
  serverTimestamp,
  onSnapshot,
  query,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { OrderData } from '@/types';
import { BindingType } from '@/types';

/** Estimates order processing time (seconds) for Firestore */
function estimateOrderTime(order: OrderData): number {
  let time = 60; // base
  for (const file of order.files) {
    time += file.pages;
    if (file.binding !== BindingType.nobinding) {
      time += 15 * 60 * file.copies; // 15 min per binding copy
    }
  }
  return time;
}

/**
 * Writes a completed order to Firestore orders collection.
 * Mirrors lib/services/firestore.dart addOrder()
 */
export async function addOrder(order: OrderData): Promise<string> {
  const ref = await addDoc(collection(db, 'orders'), {
    orderId: order.orderId,
    userName: order.userName,
    phoneNumber: order.phoneNumber,
    price: order.price,
    pages: order.pages,
    transactionId: order.transactionId,
    timestamp: serverTimestamp(),
    time: estimateOrderTime(order),
    files: order.files.map((f) => ({
      name: f.name,
      pages: f.pages,
      copies: f.copies,
      binding: f.binding,
      color: f.color,
      sides: f.sides,
    })),
  });
  return ref.id;
}

/**
 * Gets real-time queue count and total estimated wait time via Firestore aggregation.
 * Returns an unsubscribe function.
 */
export function subscribeToQueue(
  callback: (count: number, estimatedTime: number) => void
): () => void {
  const q = query(collection(db, 'orders'));
  const unsub = onSnapshot(q, async () => {
    try {
      const snap = await getAggregateFromServer(q, {
        totalCount: count(),
        totalTime: sum('time'),
      });
      callback(
        snap.data().totalCount ?? 0,
        snap.data().totalTime ?? 0
      );
    } catch {
      callback(0, 0);
    }
  });
  return unsub;
}
