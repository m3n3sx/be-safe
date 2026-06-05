'use client';

import React from 'react';
import { useAuth } from '@/contexts/AuthContext';
import LoginPage from '@/components/auth/LoginPage';
import Sidebar from '@/components/ui/Sidebar';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-coral flex items-center justify-center text-white font-bold animate-pulse">b:S</div>
          <p className="text-sm text-ink-2">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) return <LoginPage />;

  return (
    <div className="h-full flex bg-background text-ink">
      <Sidebar />
      <main className="flex-1 lg:ml-0 pt-14 lg:pt-0 pb-16 lg:pb-0 overflow-y-auto">
        {children}
      </main>
    </div>
  );
}
