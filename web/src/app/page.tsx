'use client';

import React, { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import LoginPage from '@/components/auth/LoginPage';
import Sidebar from '@/components/ui/Sidebar';
import MapView from '@/components/map/MapView';

export default function HomePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (!loading && user && localStorage.getItem('besafe.onboarded') !== '1') {
      router.replace('/onboarding');
    }
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="h-full flex items-center justify-center bg-neutral-50 dark:bg-neutral-950">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-red-500 flex items-center justify-center text-white font-bold animate-pulse">
            b:S
          </div>
          <p className="text-sm text-neutral-500">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginPage />;
  }

  return (
    <div className="h-full flex">
      <Sidebar />
      <main className="flex-1 lg:ml-0 pt-14 lg:pt-0 pb-16 lg:pb-0">
        <MapView />
      </main>
    </div>
  );
}
