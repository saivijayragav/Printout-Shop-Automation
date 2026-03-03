'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';
import { useAppStore } from '@/store/appStore';
import { initializeMessaging } from '@/services/messagingService';
import { Printer } from 'lucide-react';

const schema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(60),
  phone: z
    .string()
    .regex(/^\d{10}$/, 'Enter a valid 10-digit phone number'),
});

type FormData = z.infer<typeof schema>;

export default function LoginPage() {
  const router = useRouter();
  const setSession = useAppStore((s) => s.setSession);
  const [loading, setLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) });

  async function onSubmit(data: FormData) {
    setLoading(true);
    try {
      // Persist to localStorage (mirrors SharedPreferences in Flutter)
      localStorage.setItem('isLoggedIn', 'true');
      localStorage.setItem('userName', data.name);
      localStorage.setItem('userPhone', data.phone);

      // Set a session cookie so middleware can verify auth
      document.cookie = `session=${data.phone}; path=/; max-age=${60 * 60 * 24 * 30}`;

      // Update Zustand store
      setSession({ name: data.name, phone: data.phone, isLoggedIn: true });

      // Register FCM token (best-effort)
      initializeMessaging(data.phone).catch(console.warn);

      toast.success(`Welcome, ${data.name}!`);
      router.replace('/home');
    } catch (err) {
      toast.error('Login failed. Please try again.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-dvh flex items-center justify-center px-4 py-10 bg-background">
      <div className="w-full max-w-sm">
        {/* Header */}
        <div className="flex flex-col items-center mb-8 gap-3">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/ritlogo.jpg"
            alt="RIT Logo"
            className="w-20 h-20 rounded-full object-cover border-2 border-accent/40"
            onError={(e) => {
              (e.currentTarget as HTMLImageElement).style.display = 'none';
            }}
          />
          <div className="flex items-center gap-2 text-accent">
            <Printer size={22} />
            <span className="text-xl font-bold">RIT Arcade</span>
          </div>
          <p className="text-muted-foreground text-sm text-center">
            Campus Print Shop · RIT Chennai
          </p>
        </div>

        {/* Card */}
        <div className="bg-card border border-border rounded-2xl p-6 shadow-xl">
          <h1 className="text-lg font-semibold mb-5 text-center">Sign In</h1>

          <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-4">
            {/* Name */}
            <div className="flex flex-col gap-1">
              <label htmlFor="name" className="text-sm font-medium text-muted-foreground">
                Full Name
              </label>
              <input
                id="name"
                type="text"
                autoComplete="name"
                placeholder="e.g. Sai Vijay"
                {...register('name')}
                className="w-full bg-background border border-border rounded-lg px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
              />
              {errors.name && (
                <p className="text-xs text-destructive">{errors.name.message}</p>
              )}
            </div>

            {/* Phone */}
            <div className="flex flex-col gap-1">
              <label htmlFor="phone" className="text-sm font-medium text-muted-foreground">
                Phone Number
              </label>
              <input
                id="phone"
                type="tel"
                inputMode="numeric"
                autoComplete="tel"
                placeholder="10-digit mobile number"
                maxLength={10}
                {...register('phone')}
                className="w-full bg-background border border-border rounded-lg px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-accent/50 focus:border-accent transition"
              />
              {errors.phone && (
                <p className="text-xs text-destructive">{errors.phone.message}</p>
              )}
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="mt-1 w-full bg-accent text-accent-foreground font-semibold rounded-lg py-2.5 text-sm hover:bg-accent/90 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition"
            >
              {loading ? 'Signing in…' : 'Continue'}
            </button>
          </form>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-5">
          *No refund will be provided after payment.
        </p>
      </div>
    </div>
  );
}
