// Enums
export enum PrintColor {
  bw = 'bw',
  color = 'color',
}

export enum Sides {
  both = 'both',
  single = 'single',
  four = 'four',
}

export enum BindingType {
  spiral = 'spiral',
  soft = 'soft',
  nobinding = 'nobinding',
}

// Per-file data model
export interface FileData {
  name: string;
  size: number;   // bytes
  pages: number;
  bytes: Uint8Array<ArrayBuffer>;
  copies: number;
  type: string;   // mime type
  binding: BindingType;
  color: PrintColor;
  sides: Sides;
}

// Pricing breakdown for one file
export interface ItemPrice {
  description: string;
  pages: number;
  bwRate: number;
  colorRate: number;
  cost: number;
  sides: string;
  bindingNote: string;
}

// Full receipt returned by the pricing API
export interface Receipt {
  totalPrice: number;
  currency: string;
  items: ItemPrice[];
}

// Complete order
export interface OrderData {
  orderId: string;
  files: FileData[];
  pages: number;
  price: number;
  receipt: Receipt;
  userName: string;
  phoneNumber: string;
  transactionId: string;
  timestamp: string;
}

// Payment record stored in localStorage
export interface Payment {
  id: string;
  status: 'success' | 'failure';
  paymentId: string;
  orderId: string;
  signature: string;
  timestamp: string;
  customProcessId: string;
}

// Notification record stored in localStorage
export interface NotificationItem {
  title: string;
  body: string;
  timestamp: string;
}

// User session (stored in localStorage + Zustand)
export interface UserSession {
  name: string;
  phone: string;
  isLoggedIn: boolean;
}
