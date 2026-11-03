'use client';

import React from 'react';
import { ThemeProvider } from '@/contexts/ThemeContext';
import { AuthProvider } from '@/contexts/AuthContext';
import { SocketProvider } from '@/contexts/SocketContext';
import { AppShell } from '@/components/layout/AppShell';
import { ToastProvider } from '@/components/ui/Toast';
import { NotificationsProvider } from '@/contexts/NotificationsContext';

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider>
      <AuthProvider>
        <SocketProvider>
          <NotificationsProvider><ToastProvider><AppShell>{children}</AppShell></ToastProvider></NotificationsProvider>
        </SocketProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}
