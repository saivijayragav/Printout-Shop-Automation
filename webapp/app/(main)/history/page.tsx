'use client';

import { useEffect, useState } from 'react';
import { Payment } from '@/types';
import {
  getAllPayments,
  clearPayments,
  deletePaymentsByIds,
} from '@/services/paymentService';
import { CheckCircle2, XCircle, Trash2, History, ChevronDown, ChevronUp } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import { cn } from '@/lib/utils';
import toast from 'react-hot-toast';

export default function HistoryPage() {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [confirmClear, setConfirmClear] = useState(false);

  function reload() {
    setPayments(getAllPayments());
    setSelected(new Set());
  }

  useEffect(() => { reload(); }, []);

  function toggleSelect(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      next.has(id) ? next.delete(id) : next.add(id);
      return next;
    });
  }

  function deleteSelected() {
    deletePaymentsByIds([...selected]);
    reload();
    toast.success(`Deleted ${selected.size} record(s)`);
  }

  function handleClearAll() {
    clearPayments();
    reload();
    setConfirmClear(false);
    toast.success('All history cleared');
  }

  function formatTime(iso: string) {
    try {
      return new Intl.DateTimeFormat('en-IN', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(iso));
    } catch { return iso; }
  }

  return (
    <div className="flex flex-col gap-4 max-w-2xl mx-auto">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <History size={20} className="text-accent" /> Payment History
        </h1>
        <div className="flex items-center gap-2">
          {selected.size > 0 && (
            <button
              onClick={deleteSelected}
              className="flex items-center gap-1.5 text-sm text-destructive hover:text-red-400 transition-colors"
            >
              <Trash2 size={15} /> Delete ({selected.size})
            </button>
          )}
          {payments.length > 0 && selected.size === 0 && (
            <button
              onClick={() => setConfirmClear(true)}
              className="text-sm text-muted-foreground hover:text-destructive transition-colors"
            >
              Clear all
            </button>
          )}
        </div>
      </div>

      {payments.length === 0 ? (
        <div className="flex flex-col items-center justify-center gap-3 py-20 text-muted-foreground">
          <History size={48} strokeWidth={1.2} />
          <p className="text-sm">No payment records yet</p>
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {payments.map((p) => {
            const isExpanded = expandedId === p.id;
            const isSelected = selected.has(p.id);
            return (
              <div
                key={p.id}
                className={cn(
                  'bg-card border rounded-xl transition-colors',
                  isSelected ? 'border-accent/60' : 'border-border'
                )}
              >
                <div
                  className="flex items-center gap-3 p-4 cursor-pointer"
                  onClick={() => setExpandedId(isExpanded ? null : p.id)}
                >
                  {/* Select checkbox */}
                  <input
                    type="checkbox"
                    checked={isSelected}
                    onChange={(e) => { e.stopPropagation(); toggleSelect(p.id); }}
                    onClick={(e) => e.stopPropagation()}
                    className="accent-[#6EACDA] w-4 h-4 rounded shrink-0"
                  />
                  {/* Status icon */}
                  {p.status === 'success' ? (
                    <CheckCircle2 size={20} className="text-green-400 shrink-0" />
                  ) : (
                    <XCircle size={20} className="text-destructive shrink-0" />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">Order #{p.orderId}</p>
                    <p className="text-xs text-muted-foreground">{formatTime(p.timestamp)}</p>
                  </div>
                  {isExpanded ? (
                    <ChevronUp size={16} className="text-muted-foreground shrink-0" />
                  ) : (
                    <ChevronDown size={16} className="text-muted-foreground shrink-0" />
                  )}
                </div>
                {isExpanded && (
                  <div className="px-4 pb-4 pt-3 text-xs text-muted-foreground flex flex-col gap-3 border-t border-border">
                    {/* QR Code for order */}
                    <div className="flex justify-center">
                      <div className="bg-white rounded-xl p-3">
                        <QRCodeSVG
                          value={p.orderId}
                          size={96}
                          fgColor="#021526"
                          bgColor="#ffffff"
                          level="H"
                        />
                      </div>
                    </div>
                    <div className="flex flex-col gap-1">
                      <p><span className="text-foreground font-medium">Payment ID:</span> {p.paymentId || '—'}</p>
                      <p><span className="text-foreground font-medium">Status:</span> {p.status === 'success' ? '✅ Success' : '❌ Failed'}</p>
                      {p.customProcessId && (
                        <p><span className="text-foreground font-medium">Process ID:</span> {p.customProcessId}</p>
                      )}
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Confirm clear dialog */}
      {confirmClear && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 px-4">
          <div className="bg-card border border-border rounded-2xl p-6 w-full max-w-sm shadow-2xl">
            <h2 className="text-lg font-semibold mb-2">Clear all history?</h2>
            <p className="text-sm text-muted-foreground mb-5">This cannot be undone.</p>
            <div className="flex gap-3">
              <button onClick={() => setConfirmClear(false)} className="flex-1 py-2.5 rounded-lg border border-border text-sm hover:bg-muted transition-colors">Cancel</button>
              <button onClick={handleClearAll} className="flex-1 py-2.5 rounded-lg bg-destructive text-white text-sm hover:bg-red-500 transition-colors">Clear</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
