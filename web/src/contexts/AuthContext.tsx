'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';
import type { User } from '@/types';
import { removeSession } from '@/lib/storage';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  sessionError: string | null;
  login: (email: string, password: string) => Promise<string | null>;
  register: (
    email: string,
    password: string,
    username: string,
    referralCode?: string,
  ) => Promise<string | null>;
  loginWithGoogle: (
    idToken: string,
    email: string,
    displayName: string,
    avatarUrl?: string,
  ) => Promise<string | null>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [sessionError, setSessionError] = useState<string | null>(null);

  const fetchUser = useCallback(async () => {
    if (!api.getToken()) {
      setLoading(false);
      return;
    }
    const res = await api.get<User>('/users/me');
    setSessionError(null);
    if (!res.error && res.id) {
      setUser(res as User);
    } else if (res.httpStatus === 401 || res.httpStatus === 403) {
      api.setToken(null);
      setUser(null);
    } else {
      setSessionError('Nie udało się sprawdzić sesji. Spróbuj ponownie.');
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => void fetchUser(), 0);
    const expired = () => {
      api.setToken(null);
      setUser(null);
    };
    window.addEventListener('besafe:session-expired', expired);
    return () => {
      clearTimeout(timer);
      window.removeEventListener('besafe:session-expired', expired);
    };
  }, [fetchUser]);

  const login = async (email: string, password: string): Promise<string | null> => {
    const res = await api.post<{ token: string; user: User }>('/auth/login', { email, password });
    if (res.error) return res.error;
    if (!res.token || !res.user?.id) return 'Nieprawidłowa odpowiedź serwera.';
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const register = async (
    email: string,
    password: string,
    username: string,
    referralCode?: string,
  ): Promise<string | null> => {
    const res = await api.post<{ token: string; user: User }>('/auth/register', {
      email,
      password,
      username,
      ...(referralCode ? { referral_code: referralCode } : {}),
    });
    if (res.error) return res.error;
    if (!res.token || !res.user?.id) return 'Nieprawidłowa odpowiedź serwera.';
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const loginWithGoogle = async (
    idToken: string,
    email: string,
    displayName: string,
    avatarUrl?: string,
  ): Promise<string | null> => {
    // Backend weryfikuje id_token i bierze dane z tokena; email/display_name/avatar_url
    // zostają tylko dla zgodności ze starszym backendem.
    const res = await api.post<{ token: string; user: User }>('/auth/google', {
      id_token: idToken,
      email,
      display_name: displayName,
      avatar_url: avatarUrl,
    });
    if (res.error) return res.error;
    if (!res.token || !res.user?.id) return 'Nieprawidłowa odpowiedź serwera.';
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const logout = () => {
    api.setToken(null);
    removeSession('besafe.explorer');
    removeSession('besafe.report');
    setUser(null);
  };

  const refreshUser = async () => {
    await fetchUser();
  };

  return (
    <AuthContext.Provider
      value={{ user, loading, sessionError, login, register, loginWithGoogle, logout, refreshUser }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
