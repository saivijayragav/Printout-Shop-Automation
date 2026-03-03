import { create } from 'zustand';
import { FileData, OrderData, UserSession } from '@/types';

interface AppStore {
  // User session
  session: UserSession;
  setSession: (session: UserSession) => void;
  clearSession: () => void;

  // Cart: list of configured files to print
  cart: FileData[];
  addToCart: (file: FileData) => void;
  updateCartItem: (index: number, file: Partial<FileData>) => void;
  removeFromCart: (index: number) => void;
  clearCart: () => void;

  // Admin settings
  liveOrdersEnabled: boolean;
  setLiveOrdersEnabled: (enabled: boolean) => void;

  // Current pending order (set just before navigating to order-summary)
  pendingOrder: OrderData | null;
  setPendingOrder: (order: OrderData | null) => void;
}

export const useAppStore = create<AppStore>((set) => ({
  session: { name: '', phone: '', isLoggedIn: false },
  setSession: (session) => set({ session }),
  clearSession: () =>
    set({ session: { name: '', phone: '', isLoggedIn: false } }),

  cart: [],
  addToCart: (file) => set((state) => ({ cart: [...state.cart, file] })),
  updateCartItem: (index, file) =>
    set((state) => {
      const newCart = [...state.cart];
      newCart[index] = { ...newCart[index], ...file };
      return { cart: newCart };
    }),
  removeFromCart: (index) =>
    set((state) => ({ cart: state.cart.filter((_, i) => i !== index) })),
  clearCart: () => set({ cart: [] }),

  liveOrdersEnabled: true,
  setLiveOrdersEnabled: (enabled) => set({ liveOrdersEnabled: enabled }),

  pendingOrder: null,
  setPendingOrder: (order) => set({ pendingOrder: order }),
}));
