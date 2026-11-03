import { Suspense } from 'react';
import { AccountRecovery } from '@/components/auth/AccountRecovery';
import { Skeleton } from '@/components/ui/Skeleton';
export default function ForgotPasswordPage() {
  return (
    <Suspense fallback={<Skeleton />}>
      <AccountRecovery mode="forgot" />
    </Suspense>
  );
}
