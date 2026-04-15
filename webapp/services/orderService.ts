import { OrderData } from '@/types';

/**
 * Sends the completed order to the Spring Boot backend.
 * Mirrors lib/services/order_service.dart
 */
export async function sendOrderToBackend(order: OrderData): Promise<void> {
  const url = `${process.env.NEXT_PUBLIC_ORDER_API_URL}/pay`;

  const payload = {
    orderId: order.orderId,
    userName: order.userName,
    phoneNumber: order.phoneNumber,
    price: order.price,
    pages: order.pages,
    transactionId: order.transactionId,
    timestamp: order.timestamp.substring(0, 19),
    files: order.files.map((f) => ({
      name: f.name,
      size: typeof f.size === 'number' ? f.size : 0,
      type: f.type || 'application/pdf',
      pages: f.pages,
      copies: f.copies,
      binding: f.binding,
      color: f.color,
      sides: f.sides,
    })),
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (res.status !== 200 && res.status !== 201) {
    throw new Error(`Backend returned ${res.status}`);
  }
}
