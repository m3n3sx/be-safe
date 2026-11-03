import type { ReactNode } from 'react';
// Compatibility wrapper: AppShell is mounted once in the root providers.
export default function AppLayout({ children }: { children: ReactNode }) { return <>{children}</>; }
