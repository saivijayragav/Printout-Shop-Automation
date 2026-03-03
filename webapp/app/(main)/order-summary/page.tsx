'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import Script from 'next/script';
import toast from 'react-hot-toast';
import { useAppStore } from '@/store/appStore';
import { insertPayment } from '@/services/paymentService';
import { generateCode } from '@/utils/randomCode';
import { ItemPrice } from '@/types';
import { CreditCard, Loader2, FileText, ArrowLeft } from 'lucide-react';

export default function OrderSummaryPage() {
  const router = useRouter();
  const { pendingOrder, session, setPendingOrder } = useAppStore();
  const [paying, setPaying] = useState(false);
  const scriptLoaded = useRef(false);

  // Guard: if no pending order, go back to upload
  useEffect(() => {
    if (!pendingOrder) router.replace('/upload');
  }, [pendingOrder, router]);

  if (!pendingOrder) {
    return (
      <div className="flex items-center justify-center py-20">
        <Loader2 className="animate-spin text-accent" size={28} />
      </div>
    );
  }

  function handlePayment() {
    if (!pendingOrder) return;
    if (!scriptLoaded.current || !window.Razorpay) {
      toast.error('Payment SDK not loaded yet. Please wait a moment.');
      return;
    }

    setPaying(true);
    const razorpay = new window.Razorpay({
      key: process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID!,
      amount: Math.round(pendingOrder.price * 100), // paise
      currency: pendingOrder.receipt.currency || 'INR',
      name: 'RIT Arcade Print Shop',
      description: `Order #${pendingOrder.orderId}`,
      prefill: {
        name: session.name,
        contact: session.phone,
      },
      theme: { color: '#6EACDA' },
      handler: (response) => {
        setPaying(false);
        // Save success record
        insertPayment({
          id: generateCode(12),
          status: 'success',
          paymentId: response.razorpay_payment_id,
          orderId: pendingOrder.orderId,
          signature: response.razorpay_signature ?? '',
          timestamp: new Date().toISOString(),
          customProcessId: pendingOrder.orderId,
        });
        // Update order with transaction id
        setPendingOrder({
          ...pendingOrder,
          transactionId: response.razorpay_payment_id,
        });
        router.push('/order-processing');
      },
      modal: {
        ondismiss: () => {
          setPaying(false);
          toast.error('Payment cancelled.');
          // Save failure record
          insertPayment({
            id: generateCode(12),
            status: 'failure',
            paymentId: '',
            orderId: pendingOrder.orderId,
            signature: '',
            timestamp: new Date().toISOString(),
            customProcessId: pendingOrder.orderId,
          });
        },
      },
    });

    razorpay.on('payment.failed', (response: { error: { code: string; description: string } }) => {
      setPaying(false);
      toast.error(`Payment failed: ${response.error.description}`);
      insertPayment({
        id: generateCode(12),
        status: 'failure',
        paymentId: '',
        orderId: pendingOrder.orderId,
        signature: '',
        timestamp: new Date().toISOString(),
        customProcessId: pendingOrder.orderId,
      });
    });

    razorpay.open();
  }

  return (
    <>
      {/* Razorpay Checkout JS */}
      <Script
        src="https://checkout.razorpay.com/v1/checkout.js"
        onLoad={() => { scriptLoaded.current = true; }}
        strategy="lazyOnload"
      />

      <div className="flex flex-col gap-5 max-w-2xl mx-auto">
        {/* Header */}
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="text-muted-foreground hover:text-foreground transition-colors">
            <ArrowLeft size={20} />
          </button>
          <h1 className="text-xl font-bold">Order Summary</h1>
        </div>

        {/* Items list */}
        <div className="flex flex-col gap-3">
          {pendingOrder.receipt.items.map((item: ItemPrice, i: number) => (
            <div key={i} className="bg-card border border-border rounded-xl p-4">
              <div className="flex items-start justify-between gap-2 mb-3">
                <div className="flex items-start gap-2 min-w-0">
                  <FileText size={18} className="text-accent shrink-0 mt-0.5" />
                  <p className="text-sm font-medium truncate">{item.description}</p>
                </div>
                <p className="text-sm font-bold text-accent shrink-0">₹{item.cost}</p>
              </div>
              <div className="flex flex-wrap gap-1.5">
                <Chip>{item.pages} pages</Chip>
                <Chip>{item.sides}</Chip>
                {item.bindingNote && <Chip>{item.bindingNote}</Chip>}
                {item.colorRate > 0 ? <Chip>Color</Chip> : <Chip>B&W</Chip>}
              </div>
            </div>
          ))}
        </div>

        {/* Total */}
        <div className="bg-accent/10 border border-accent/30 rounded-xl p-4 flex items-center justify-between">
          <span className="font-semibold text-sm">Total Amount</span>
          <span className="text-2xl font-bold text-accent">
            ₹{pendingOrder.price}
          </span>
        </div>

        {/* Disclaimer */}
        <p className="text-xs text-muted-foreground text-center">
          *No refund will be provided after payment is processed.
        </p>

        {/* Pay button */}
        <button
          onClick={handlePayment}
          disabled={paying}
          className="w-full bg-accent text-accent-foreground font-semibold rounded-xl py-4 text-sm flex items-center justify-center gap-2 hover:bg-accent/90 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition"
        >
          {paying ? (
            <><Loader2 size={16} className="animate-spin" /> Processing…</>
          ) : (
            <><CreditCard size={16} /> Pay ₹{pendingOrder.price}</>
          )}
        </button>
      </div>
    </>
  );
}

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-muted text-muted-foreground border border-border">
      {children}
    </span>
  );
}
