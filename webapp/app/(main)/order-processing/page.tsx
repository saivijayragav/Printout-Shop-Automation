'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAppStore } from '@/store/appStore';
import { sanitizeFileNames } from '@/utils/preprocessing';
import { sendOrderToBackend } from '@/services/orderService';
import { addOrder } from '@/services/firestoreService';
import { CheckCircle2, XCircle, Loader2, RotateCcw, History, Download } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import toast from 'react-hot-toast';

type Status = 'idle' | 'uploading' | 'sending' | 'success' | 'error';

export default function OrderProcessingPage() {
  const router = useRouter();
  const { pendingOrder, clearCart, setPendingOrder } = useAppStore();
  const [status, setStatus] = useState<Status>('idle');
  const [errorMsg, setErrorMsg] = useState('');
  const [uploadProgress, setUploadProgress] = useState(0);
  const [completedOrderId, setCompletedOrderId] = useState<string | null>(null);
  const [downloading, setDownloading] = useState(false);
  const ran = useRef(false);

  useEffect(() => {
    if (!pendingOrder) {
      router.replace('/upload');
      return;
    }
    if (ran.current) return;
    ran.current = true;
    processOrder();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function processOrder() {
    if (!pendingOrder) return;
    setStatus('uploading');

    try {
      // Sanitize file names
      const sanitizedFiles = await sanitizeFileNames(pendingOrder.files);
      const order = { ...pendingOrder, files: sanitizedFiles };

      // Upload each file to Cloudflare R2 via our API route
      for (let i = 0; i < order.files.length; i++) {
        const file = order.files[i];
        const objectKey = `${order.orderId}_${file.name}`;

        const formData = new FormData();
        formData.append('file', new Blob([file.bytes.buffer as ArrayBuffer], { type: file.type }));
        formData.append('objectKey', objectKey);
        formData.append('contentType', file.type);

        const res = await fetch('/api/upload', { method: 'POST', body: formData });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          throw new Error(err.error ?? `Upload failed for ${file.name}`);
        }

        setUploadProgress(Math.round(((i + 1) / order.files.length) * 100));
      }

      // Send order to Spring Boot backend
      setStatus('sending');
      await sendOrderToBackend(order);

      // Write to Firestore
      await addOrder(order);

      // Save the order ID before clearing
      setCompletedOrderId(order.orderId);

      // Clear cart
      clearCart();
      setPendingOrder(null);
      setStatus('success');
    } catch (err) {
      console.error(err);
      setErrorMsg(err instanceof Error ? err.message : 'An unexpected error occurred.');
      setStatus('error');
    }
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-[60dvh] gap-6 px-4 text-center max-w-sm mx-auto">
      {(status === 'uploading' || status === 'sending' || status === 'idle') && (
        <>
          <Loader2 size={56} className="animate-spin text-accent" />
          <div>
            <p className="font-semibold text-lg">
              {status === 'uploading' ? 'Uploading files…' : 'Placing order…'}
            </p>
            {status === 'uploading' && (
              <p className="text-sm text-muted-foreground mt-1">{uploadProgress}% complete</p>
            )}
          </div>
          {/* Progress bar */}
          {status === 'uploading' && (
            <div className="w-full max-w-xs bg-muted rounded-full h-2">
              <div
                className="bg-accent h-2 rounded-full transition-all duration-300"
                style={{ width: `${uploadProgress}%` }}
              />
            </div>
          )}
        </>
      )}

      {status === 'success' && completedOrderId && (
        <>
          <CheckCircle2 size={64} className="text-green-400" strokeWidth={1.5} />
          <div>
            <p className="font-bold text-xl">Order Placed!</p>
            <p className="text-sm text-muted-foreground mt-2">
              Your files have been uploaded and your order is being processed.
            </p>
          </div>

          {/* QR Code */}
          <div className="bg-white rounded-2xl p-5 shadow-lg">
            <QRCodeSVG
              value={completedOrderId}
              size={180}
              fgColor="#021526"
              bgColor="#ffffff"
              level="H"
            />
          </div>
          <p className="text-sm text-muted-foreground">
            Order ID: <span className="text-accent font-mono font-semibold">{completedOrderId}</span>
          </p>

          <div className="flex flex-col gap-2 w-full">
            {/* Download cover PDF */}
            <button
              onClick={async () => {
                setDownloading(true);
                try {
                  const res = await fetch('/api/generate-pdf-cover', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ code: completedOrderId }),
                  });
                  if (!res.ok) throw new Error('Failed to generate PDF');
                  const blob = await res.blob();
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement('a');
                  a.href = url;
                  a.download = `order_${completedOrderId}.pdf`;
                  a.click();
                  URL.revokeObjectURL(url);
                } catch {
                  toast.error('Could not download cover PDF.');
                } finally {
                  setDownloading(false);
                }
              }}
              disabled={downloading}
              className="w-full flex items-center justify-center gap-2 border border-border rounded-xl py-3 text-sm font-medium hover:bg-muted active:scale-95 disabled:opacity-50 transition"
            >
              {downloading ? (
                <><Loader2 size={15} className="animate-spin" /> Generating PDF…</>
              ) : (
                <><Download size={15} /> Download QR as PDF</>
              )}
            </button>

            <button
              onClick={() => router.replace('/history')}
              className="w-full flex items-center justify-center gap-2 bg-accent text-accent-foreground font-semibold rounded-xl py-3 text-sm hover:bg-accent/90 active:scale-95 transition"
            >
              <History size={16} /> View Order History
            </button>
          </div>
        </>
      )}

      {status === 'error' && (
        <>
          <XCircle size={64} className="text-destructive" strokeWidth={1.5} />
          <div>
            <p className="font-bold text-xl">Something went wrong</p>
            <p className="text-sm text-muted-foreground mt-2">{errorMsg}</p>
          </div>
          <div className="flex flex-col gap-2 w-full">
            <button
              onClick={() => {
                ran.current = false;
                setUploadProgress(0);
                processOrder();
              }}
              className="w-full flex items-center justify-center gap-2 bg-accent text-accent-foreground font-semibold rounded-xl py-3 text-sm hover:bg-accent/90 transition"
            >
              <RotateCcw size={15} /> Retry
            </button>
            <button
              onClick={() => router.replace('/upload')}
              className="w-full py-3 rounded-xl border border-border text-sm hover:bg-muted transition-colors"
            >
              Back to Upload
            </button>
          </div>
        </>
      )}
    </div>
  );
}
