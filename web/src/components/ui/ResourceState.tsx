import { ErrorState } from './ErrorState';
import { EmptyState } from './EmptyState';
import { Skeleton } from './Skeleton';

export function ResourceState({
  loading,
  error,
  empty,
  onRetry,
}: {
  loading: boolean;
  error: string;
  empty: boolean;
  onRetry: () => void;
}) {
  if (error) return <ErrorState message={error} onRetry={onRetry} />;
  if (loading) return <Skeleton />;
  if (empty)
    return (
      <EmptyState
        title="Brak danych do wyświetlenia"
        description="Zmień filtr lub wróć tutaj później."
      />
    );
  return null;
}
