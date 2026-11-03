import { Suspense } from 'react';
import { AccountRecovery } from '@/components/auth/AccountRecovery';
import { Skeleton } from '@/components/ui/Skeleton';
export default function ResetPasswordPage() { return <Suspense fallback={<Skeleton />}><AccountRecovery mode="reset" /></Suspense>; }
