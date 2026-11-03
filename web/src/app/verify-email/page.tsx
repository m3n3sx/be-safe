import { Suspense } from 'react';
import { AccountRecovery } from '@/components/auth/AccountRecovery';
import { Skeleton } from '@/components/ui/Skeleton';
export default function VerifyEmailPage() {
  return (
    <Suspense fallback={<Skeleton />}>
      <AccountRecovery mode="verify" />
    </Suspense>
  );
}
