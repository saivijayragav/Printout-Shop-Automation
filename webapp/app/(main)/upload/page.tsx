'use client';

import { useCallback, useState } from 'react';
import { useDropzone } from 'react-dropzone';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import { BindingType, FileData, OrderData, PrintColor, Sides } from '@/types';
import { useAppStore } from '@/store/appStore';
import { getPrice } from '@/services/priceService';
import { generateCode } from '@/utils/randomCode';
import PrintConfigDialog from '@/components/PrintConfigDialog';
import { cn } from '@/lib/utils';
import {
  UploadCloud,
  FileText,
  Image as ImageIcon,
  Trash2,
  Plus,
  Minus,
  ChevronRight,
  AlertTriangle,
  Loader2,
} from 'lucide-react';

type PendingFile = Omit<FileData, 'binding' | 'color' | 'sides' | 'copies'>;

/** Count pages in a PDF using pdfjs-dist (loaded lazily to avoid SSR issues) */
async function countPdfPages(buffer: ArrayBuffer): Promise<number> {
  const { getDocument, GlobalWorkerOptions, version } = await import('pdfjs-dist');
  if (!GlobalWorkerOptions.workerSrc) {
    GlobalWorkerOptions.workerSrc = `//unpkg.com/pdfjs-dist@${version}/build/pdf.worker.min.mjs`;
  }
  const pdf = await getDocument({ data: buffer }).promise;
  return pdf.numPages;
}

export default function UploadPage() {
  const router = useRouter();
  const { cart, addToCart, updateCartItem, removeFromCart, liveOrdersEnabled, setPendingOrder, session } = useAppStore();

  const [pendingFile, setPendingFile] = useState<PendingFile | null>(null);
  const [loadingFile, setLoadingFile] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showBlockedAlert, setShowBlockedAlert] = useState(false);

  // ── Handle dropped / picked file ──
  const onDrop = useCallback(async (accepted: File[]) => {
    const file = accepted[0];
    if (!file) return;

    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/png'];
    if (!allowedTypes.includes(file.type)) {
      toast.error('Only PDF, JPG, and PNG files are allowed.');
      return;
    }

    setLoadingFile(true);
    try {
      const buffer = await file.arrayBuffer();
      const bytes = new Uint8Array(buffer);
      let pages = 1;

      if (file.type === 'application/pdf') {
        pages = await countPdfPages(buffer);
      }

      setPendingFile({
        name: file.name,
        size: file.size,
        pages,
        bytes,
        type: file.type,
      });
    } catch (err) {
      toast.error('Failed to read the file. Please try again.');
      console.error(err);
    } finally {
      setLoadingFile(false);
    }
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    multiple: false,
    accept: {
      'application/pdf': ['.pdf'],
      'image/jpeg': ['.jpg', '.jpeg'],
      'image/png': ['.png'],
    },
  });

  // ── Config dialog confirmed ──
  function handleConfigDone(config: { binding: BindingType; color: PrintColor; sides: Sides }) {
    if (!pendingFile) return;
    addToCart({ ...pendingFile, ...config, copies: 1 });
    setPendingFile(null);
    toast.success(`"${pendingFile.name}" added to cart`);
  }

  // ── Copy controls ──
  function incrementCopies(i: number) {
    updateCartItem(i, { copies: (cart[i].copies ?? 1) + 1 });
  }
  function decrementCopies(i: number) {
    const curr = cart[i].copies ?? 1;
    if (curr <= 1) return;
    updateCartItem(i, { copies: curr - 1 });
  }

  // ── Proceed to payment ──
  async function handleNext() {
    if (!liveOrdersEnabled) {
      setShowBlockedAlert(true);
      return;
    }
    if (cart.length === 0) {
      toast.error('Add at least one file before proceeding.');
      return;
    }

    setSubmitting(true);
    try {
      const receipt = await getPrice(cart);
      const orderId = generateCode(6);
      const order: OrderData = {
        orderId,
        files: cart,
        pages: cart.reduce((sum, f) => sum + f.pages * f.copies, 0),
        price: receipt.totalPrice,
        receipt,
        userName: session.name,
        phoneNumber: session.phone,
        transactionId: '',
        timestamp: new Date().toISOString(),
      };
      setPendingOrder(order);
      router.push('/order-summary');
    } catch (err) {
      toast.error('Could not fetch price. Check your connection and try again.');
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  }

  function sideLabel(s: Sides) {
    return { [Sides.single]: '1-Side', [Sides.both]: '2-Side', [Sides.four]: '4-Side' }[s];
  }
  function colorLabel(c: PrintColor) {
    return { [PrintColor.bw]: 'B&W', [PrintColor.color]: 'Color' }[c];
  }
  function bindingLabel(b: BindingType) {
    return { [BindingType.nobinding]: '', [BindingType.soft]: 'Soft', [BindingType.spiral]: 'Spiral' }[b];
  }

  return (
    <div className="flex flex-col gap-5 max-w-2xl mx-auto">
      <h1 className="text-xl font-bold">Upload Files</h1>

      {/* Drop zone */}
      <div
        {...getRootProps()}
        className={cn(
          'border-2 border-dashed rounded-2xl p-8 flex flex-col items-center justify-center gap-3 cursor-pointer transition-colors text-center',
          isDragActive
            ? 'border-accent bg-accent/10 text-accent'
            : 'border-border hover:border-accent/50 hover:bg-muted/30 text-muted-foreground'
        )}
      >
        <input {...getInputProps()} />
        {loadingFile ? (
          <Loader2 size={36} className="animate-spin text-accent" />
        ) : (
          <UploadCloud size={36} />
        )}
        <div>
          <p className="font-medium text-sm">
            {isDragActive ? 'Drop it here…' : 'Drag & drop a file here'}
          </p>
          <p className="text-xs mt-1">or click to browse · PDF, JPG, PNG</p>
        </div>
      </div>

      {/* Cart list */}
      {cart.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
            Files ({cart.length})
          </p>
          {cart.map((file, i) => (
            <div key={i} className="bg-card border border-border rounded-xl p-4 flex flex-col gap-3">
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-start gap-3 min-w-0">
                  {file.type === 'application/pdf' ? (
                    <FileText size={20} className="text-accent shrink-0 mt-0.5" />
                  ) : (
                    <ImageIcon size={20} className="text-accent shrink-0 mt-0.5" />
                  )}
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate">{file.name}</p>
                    <p className="text-xs text-muted-foreground">{file.pages} page{file.pages !== 1 ? 's' : ''}</p>
                  </div>
                </div>
                <button
                  onClick={() => removeFromCart(i)}
                  className="text-muted-foreground hover:text-destructive shrink-0 transition-colors"
                >
                  <Trash2 size={16} />
                </button>
              </div>

              {/* Config badges */}
              <div className="flex flex-wrap gap-1.5">
                <Badge>{colorLabel(file.color)}</Badge>
                <Badge>{sideLabel(file.sides)}</Badge>
                {file.binding !== BindingType.nobinding && <Badge>{bindingLabel(file.binding)}</Badge>}
              </div>

              {/* Copy counter */}
              <div className="flex items-center gap-3">
                <span className="text-xs text-muted-foreground">Copies</span>
                <div className="flex items-center gap-2 bg-background border border-border rounded-lg px-2 py-1">
                  <button onClick={() => decrementCopies(i)} disabled={file.copies <= 1} className="text-muted-foreground hover:text-foreground disabled:opacity-30 transition-colors">
                    <Minus size={14} />
                  </button>
                  <span className="text-sm font-semibold w-5 text-center">{file.copies}</span>
                  <button onClick={() => incrementCopies(i)} className="text-muted-foreground hover:text-foreground transition-colors">
                    <Plus size={14} />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Next button */}
      {cart.length > 0 && (
        <button
          onClick={handleNext}
          disabled={submitting}
          className="w-full mt-2 bg-accent text-accent-foreground font-semibold rounded-xl py-3.5 text-sm flex items-center justify-center gap-2 hover:bg-accent/90 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition"
        >
          {submitting ? (
            <><Loader2 size={16} className="animate-spin" /> Calculating price…</>
          ) : (
            <>Proceed <ChevronRight size={16} /></>
          )}
        </button>
      )}

      {/* Print config dialog */}
      {pendingFile && (
        <PrintConfigDialog
          file={pendingFile}
          onDone={handleConfigDone}
          onCancel={() => setPendingFile(null)}
        />
      )}

      {/* Orders blocked alert */}
      {showBlockedAlert && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="bg-card border border-border rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <div className="flex items-center gap-2 text-destructive mb-3">
              <AlertTriangle size={20} />
              <h2 className="font-semibold">Orders Unavailable</h2>
            </div>
            <p className="text-sm text-muted-foreground mb-5">
              The print shop is currently not accepting orders. Please try again later.
            </p>
            <button
              onClick={() => setShowBlockedAlert(false)}
              className="w-full py-2.5 rounded-xl border border-border text-sm hover:bg-muted transition-colors"
            >
              OK
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function Badge({ children }: { children: React.ReactNode }) {
  return (
    <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-accent/15 text-accent border border-accent/30">
      {children}
    </span>
  );
}
