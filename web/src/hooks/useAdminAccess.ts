'use client';

// RBAC w UI — pobiera /admin/me (role + uprawnienia) i daje can(permission).
import { useEffect, useState, useCallback } from 'react';
import api from '@/lib/api';

export interface AdminAccess {
  loading: boolean;
  isAdmin: boolean;          // ma jakąkolwiek rolę admina
  isSuperadmin: boolean;
  roles: { key: string; name: string }[];
  permissions: string[];
  can: (perm: string) => boolean;
  error?: string;
}

export function useAdminAccess(): AdminAccess {
  const [state, setState] = useState<Omit<AdminAccess, 'can'>>({
    loading: true, isAdmin: false, isSuperadmin: false, roles: [], permissions: [],
  });

  useEffect(() => {
    let alive = true;
    (async () => {
      const res = await api.get<{ roles?: { key: string; name: string }[]; permissions?: string[]; is_superadmin?: boolean; error?: string }>('/admin/me');
      if (!alive) return;
      if (res.error) {
        setState({ loading: false, isAdmin: false, isSuperadmin: false, roles: [], permissions: [], error: res.error });
        return;
      }
      setState({
        loading: false,
        isAdmin: (res.roles?.length ?? 0) > 0,
        isSuperadmin: !!res.is_superadmin,
        roles: res.roles ?? [],
        permissions: res.permissions ?? [],
      });
    })();
    return () => { alive = false; };
  }, []);

  const can = useCallback(
    (perm: string) => state.isSuperadmin || state.permissions.includes('*') || state.permissions.includes(perm),
    [state.isSuperadmin, state.permissions]
  );

  return { ...state, can };
}
