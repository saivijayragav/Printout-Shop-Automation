'use client';

import { useEffect, useState } from 'react';
import { useAppStore } from '@/store/appStore';
import { subscribeToQueue } from '@/services/firestoreService';
import { formatDuration } from '@/utils/timeCalculation';
import { Users, Clock, AlertTriangle } from 'lucide-react';

export default function HomePage() {
  const session = useAppStore((s) => s.session);
  const liveOrdersEnabled = useAppStore((s) => s.liveOrdersEnabled);
  const [queueCount, setQueueCount] = useState(0);
  const [estimatedSeconds, setEstimatedSeconds] = useState(0);

  useEffect(() => {
    const unsub = subscribeToQueue((count, totalTime) => {
      setQueueCount(count);
      setEstimatedSeconds(totalTime);
    });
    return () => unsub();
  }, []);

  return (
    <div className="flex flex-col gap-6 max-w-2xl mx-auto">
      {/* Greeting */}
      <div>
        <h1 className="text-2xl font-bold">
          Hello, {session.name || 'there'} 👋
        </h1>
        <p className="text-muted-foreground text-sm mt-1">
          RIT Campus Print Shop
        </p>
      </div>

      {/* Live orders disabled banner */}
      {!liveOrdersEnabled && (
        <div className="flex items-start gap-3 p-4 rounded-xl bg-destructive/10 border border-destructive/30 text-sm">
          <AlertTriangle size={18} className="text-destructive shrink-0 mt-0.5" />
          <p className="text-destructive">
            Orders are temporarily disabled by the admin. Please check back later.
          </p>
        </div>
      )}

      {/* Queue stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-card border border-border rounded-2xl p-5 flex flex-col gap-2">
          <div className="flex items-center gap-2 text-muted-foreground text-sm">
            <Users size={16} />
            Orders in Queue
          </div>
          <p className="text-4xl font-bold text-accent">{queueCount}</p>
        </div>
        <div className="bg-card border border-border rounded-2xl p-5 flex flex-col gap-2">
          <div className="flex items-center gap-2 text-muted-foreground text-sm">
            <Clock size={16} />
            Est. Wait
          </div>
          <p className="text-4xl font-bold text-accent">
            {estimatedSeconds > 0 ? formatDuration(estimatedSeconds) : '—'}
          </p>
        </div>
      </div>

      {/* Queue illustration */}
      <div className="bg-card border border-border rounded-2xl p-6 flex flex-col items-center text-center gap-3">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/queue.png"
          alt="Queue"
          className="w-32 h-32 object-contain opacity-80"
          onError={(e) => {
            (e.currentTarget as HTMLImageElement).style.display = 'none';
          }}
        />
        <p className="text-muted-foreground text-sm">
          Upload your files from the<br />
          <strong className="text-foreground">Upload</strong> tab to place a new order.
        </p>
      </div>

      {/* Disclaimer */}
      <p className="text-center text-xs text-muted-foreground pb-2">
        *No refund will be provided after payment is processed.
      </p>
    </div>
  );
}
