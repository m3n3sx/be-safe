'use client';
import type { ReactNode } from 'react';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { routeFor } from '@/lib/navigation';
import LoginPage from '@/components/auth/LoginPage';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/ui/ErrorState';
import { AppTopBar } from './AppTopBar';
import { MobileTabBar } from './MobileTabBar';
import { DesktopRail } from './DesktopRail';
import { SignalLayer } from '@/components/notifications/SignalLayer';
export function AppShell({ children }: { children: ReactNode }) {
  const { user, loading, sessionError, refreshUser } = useAuth();
  const path = usePathname();
  const protectedPage = routeFor(path)?.public !== true && !!routeFor(path);
  return (
    <div className={`app-frame ${user ? 'authenticated' : ''}`}>
      <a className="skip-link" href="#main-content">
        Przejdź do treści
      </a>
      {user && <DesktopRail />}
      <AppTopBar />
      {user && <SignalLayer />}
      <main id="main-content" tabIndex={-1} className="app-main">
        {loading && protectedPage ? (
          <Skeleton label="Przywracanie sesji…" />
        ) : !user && protectedPage ? (
          sessionError ? (
            <div className="form-container">
              <ErrorState message={sessionError} onRetry={refreshUser} />
            </div>
          ) : (
            <LoginPage />
          )
        ) : (
          children
        )}
      </main>
      {user && <MobileTabBar />}
    </div>
  );
}
