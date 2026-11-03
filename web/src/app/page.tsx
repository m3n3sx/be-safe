'use client';
import { useAuth } from '@/contexts/AuthContext';
import LoginPage from '@/components/auth/LoginPage';
import NearbyExplorer from '@/components/map/NearbyExplorer';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/ui/ErrorState';
export default function HomePage() {
  const { user, loading, sessionError, refreshUser } = useAuth();
  if (loading) return <Skeleton label="Przywracanie sesji…" />;
  if (sessionError && !user) return <div className="form-container"><ErrorState message={sessionError} onRetry={refreshUser} /></div>;
  return user ? <NearbyExplorer /> : <LoginPage />;
}
