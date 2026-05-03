'use client';

import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import api from '@/lib/api';
import type { User } from '@/types';

interface AuthContextType {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<string | null>;
  register: (email: string, password: string, username: string) => Promise<string | null>;
  loginWithGoogle: (email: string, displayName: string, avatarUrl?: string) => Promise<string | null>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUser = useCallback(async () => {
    if (!api.getToken()) {
      setLoading(false);
      return;
    }
    const res = await api.get<User>('/users/me');
    if (!res.error) {
      setUser(res as User);
    } else {
      api.setToken(null);
      setUser(null);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchUser();
  }, [fetchUser]);

  const login = async (email: string, password: string): Promise<string | null> => {
    const res = await api.post<{ token: string; user: User }>('/auth/login', { email, password });
    if (res.error) return res.error;
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const register = async (email: string, password: string, username: string): Promise<string | null> => {
    const res = await api.post<{ token: string; user: User }>('/auth/register', { email, password, username });
    if (res.error) return res.error;
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const loginWithGoogle = async (email: string, displayName: string, avatarUrl?: string): Promise<string | null> => {
    const res = await api.post<{ token: string; user: User }>('/auth/google', {
      email,
      display_name: displayName,
      avatar_url: avatarUrl,
    });
    if (res.error) return res.error;
    api.setToken(res.token);
    setUser(res.user);
    return null;
  };

  const logout = () => {
    api.setToken(null);
    setUser(null);
  };

  const refreshUser = async () => {
    await fetchUser();
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, register, loginWithGoogle, logout, refreshUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
