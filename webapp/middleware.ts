import { NextRequest, NextResponse } from 'next/server';

// Routes that don't need authentication
const PUBLIC_ROUTES = ['/login', '/'];

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Allow public routes, static assets, and API routes
  if (
    PUBLIC_ROUTES.some((r) => pathname === r || (r !== '/' && pathname.startsWith(r))) ||
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname === '/favicon.ico' ||
    pathname.endsWith('.js') ||
    pathname.endsWith('.json') ||
    pathname.endsWith('.png') ||
    pathname.endsWith('.jpg') ||
    pathname.endsWith('.svg')
  ) {
    return NextResponse.next();
  }

  // Check session cookie (set at login time)
  const session = req.cookies.get('session')?.value;
  if (!session) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
