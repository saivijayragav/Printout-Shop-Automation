'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { cn } from '@/lib/utils';
import { useAppStore } from '@/store/appStore';
import {
  Home,
  Upload,
  Bell,
  History,
  LogOut,
  User,
  Phone,
  Mail,
  MapPin,
  X,
} from 'lucide-react';

const NAV_ITEMS = [
  { href: '/home', label: 'Home', icon: Home },
  { href: '/upload', label: 'Upload', icon: Upload },
  { href: '/notifications', label: 'Alerts', icon: Bell },
  { href: '/history', label: 'History', icon: History },
];

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { session, clearSession } = useAppStore();
  const [showProfile, setShowProfile] = useState(false);
  const [showContact, setShowContact] = useState(false);

  function logout() {
    clearSession();
    localStorage.removeItem('isLoggedIn');
    localStorage.removeItem('userName');
    localStorage.removeItem('userPhone');
    // Clear session cookie
    document.cookie = 'session=; Max-Age=0; path=/';
    router.replace('/login');
  }

  const initials = session.name
    ? session.name
        .split(' ')
        .map((w) => w[0])
        .join('')
        .toUpperCase()
        .slice(0, 2)
    : '?';

  return (
    <div className="flex h-dvh overflow-hidden">
      {/* ── Desktop sidebar ── */}
      <aside className="hidden md:flex flex-col w-56 bg-card border-r border-border shrink-0">
        {/* Branding */}
        <div className="flex items-center gap-2 px-4 py-5 border-b border-border">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/logo.jpg" alt="logo" className="w-8 h-8 rounded-full object-cover" />
          <span className="font-semibold text-sm text-accent leading-tight">RIT Arcade RS</span>
        </div>

        {/* Nav links */}
        <nav className="flex-1 flex flex-col gap-1 p-3 pt-4">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className={cn(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors',
                pathname.startsWith(href)
                  ? 'bg-accent text-accent-foreground'
                  : 'text-muted-foreground hover:bg-muted hover:text-foreground'
              )}
            >
              <Icon size={18} />
              {label}
            </Link>
          ))}
        </nav>

        {/* User area */}
        <div className="p-3 border-t border-border">
          <button
            onClick={() => setShowProfile(true)}
            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm text-muted-foreground hover:bg-muted hover:text-foreground transition-colors"
          >
            <div className="w-7 h-7 rounded-full bg-accent flex items-center justify-center text-xs font-bold text-accent-foreground shrink-0">
              {initials}
            </div>
            <span className="truncate">{session.name || 'User'}</span>
          </button>
        </div>
      </aside>

      {/* ── Main content area ── */}
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        {/* Top app bar */}
        <header className="flex items-center justify-between px-4 py-3 bg-card border-b border-border md:px-6 shrink-0">
          <div className="flex items-center gap-2">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/logo.jpg" alt="logo" className="w-7 h-7 rounded-full object-cover md:hidden" />
            <span className="font-semibold text-sm text-accent">RIT Arcade RS</span>
          </div>
          <button
            onClick={() => setShowProfile(true)}
            className="w-8 h-8 rounded-full bg-accent flex items-center justify-center text-xs font-bold text-accent-foreground"
          >
            {initials}
          </button>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto p-4 md:p-6">{children}</main>

        {/* ── Mobile bottom nav ── */}
        <nav className="md:hidden flex items-center justify-around bg-card border-t border-border shrink-0 pb-[env(safe-area-inset-bottom)]">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
            const active = pathname.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                className={cn(
                  'flex flex-col items-center gap-0.5 py-2.5 px-3 text-xs font-medium transition-colors flex-1',
                  active ? 'text-accent' : 'text-muted-foreground'
                )}
              >
                <Icon size={20} strokeWidth={active ? 2.5 : 1.8} />
                <span>{label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* ── Profile / logout drawer ── */}
      {showProfile && (
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/50">
          <div className="bg-card rounded-t-2xl md:rounded-2xl w-full max-w-sm p-6 shadow-2xl border border-border">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold">Account</h2>
              <button onClick={() => setShowProfile(false)}>
                <X size={20} className="text-muted-foreground" />
              </button>
            </div>
            <div className="flex items-center gap-4 mb-6">
              <div className="w-14 h-14 rounded-full bg-accent flex items-center justify-center text-xl font-bold text-accent-foreground">
                {initials}
              </div>
              <div>
                <p className="font-semibold">{session.name}</p>
                <p className="text-muted-foreground text-sm flex items-center gap-1">
                  <Phone size={13} /> {session.phone}
                </p>
              </div>
            </div>
            <div className="flex flex-col gap-2">
              <button
                onClick={() => { setShowProfile(false); setShowContact(true); }}
                className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground px-3 py-2 rounded-lg hover:bg-muted transition-colors"
              >
                <Mail size={16} /> Contact Us
              </button>
              <button
                onClick={logout}
                className="flex items-center gap-2 text-sm text-destructive hover:text-red-400 px-3 py-2 rounded-lg hover:bg-muted transition-colors"
              >
                <LogOut size={16} /> Logout
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Contact dialog ── */}
      {showContact && (
        <div className="fixed inset-0 z-50 flex items-end md:items-center justify-center bg-black/50">
          <div className="bg-card rounded-t-2xl md:rounded-2xl w-full max-w-sm p-6 shadow-2xl border border-border">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-lg font-semibold">Contact Us</h2>
              <button onClick={() => setShowContact(false)}>
                <X size={20} className="text-muted-foreground" />
              </button>
            </div>
            <div className="flex flex-col gap-3 text-sm text-muted-foreground">
              <div className="flex items-center gap-2"><Mail size={15} /><span>support@ritarcade.in</span></div>
              <div className="flex items-center gap-2"><Phone size={15} /><span>+91 98765 43210</span></div>
              <div className="flex items-center gap-2"><MapPin size={15} /><span>RIT Campus, Chennai</span></div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
