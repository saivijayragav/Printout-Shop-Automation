import type { Metadata, Viewport } from 'next';
import { Poppins } from 'next/font/google';
import { Toaster } from 'react-hot-toast';
import './globals.css';
import FirebaseInit from '@/components/FirebaseInit';

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['300', '400', '500', '600', '700'],
  variable: '--font-poppins',
});

export const metadata: Metadata = {
  title: 'RIT Arcade – Print Shop',
  description: 'Upload files and place print orders at RIT Campus, Chennai.',
};

export const viewport: Viewport = {
  themeColor: '#021526',
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className="dark">
      <body className={`${poppins.variable} font-poppins antialiased bg-background text-foreground`}>
        <FirebaseInit />
        {children}
        <Toaster
          position="top-center"
          toastOptions={{
            style: { background: '#0A3353', color: '#e2e8f0', border: '1px solid #6EACDA33' },
            success: { iconTheme: { primary: '#6EACDA', secondary: '#021526' } },
            error: { iconTheme: { primary: '#f87171', secondary: '#021526' } },
          }}
        />
      </body>
    </html>
  );
}
