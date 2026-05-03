'use client';

import React, { createContext, useContext, useEffect, useRef, useCallback, useState } from 'react';
import { io, Socket } from 'socket.io-client';
import { SOCKET_URL } from '@/lib/constants';
import { useAuth } from './AuthContext';
import type { Alert } from '@/types';

interface SocketContextType {
  connected: boolean;
  onNewAlert: (cb: (alert: Alert) => void) => () => void;
  onAlertUpdated: (cb: (data: { id: string; confirms: number; denies: number }) => void) => () => void;
  onAlertExpired: (cb: (data: { alert_id: string }) => void) => () => void;
  onFamilyLocation: (cb: (data: { user_id: string; lat: number; lng: number; recorded_at: string }) => void) => () => void;
  onGeofenceExit: (cb: (data: { user_id: string; username: string; geofence_name: string }) => void) => () => void;
  updateLocation: (lat: number, lng: number) => void;
}

const SocketContext = createContext<SocketContextType | null>(null);

export function SocketProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const socketRef = useRef<Socket | null>(null);
  const [connected, setConnected] = useState(false);

  const listenersRef = useRef<{
    'alert:new': Set<(a: Alert) => void>;
    'alert:updated': Set<(d: { id: string; confirms: number; denies: number }) => void>;
    'alert:expired': Set<(d: { alert_id: string }) => void>;
    'family:location': Set<(d: { user_id: string; lat: number; lng: number; recorded_at: string }) => void>;
    'family:geofence_exit': Set<(d: { user_id: string; username: string; geofence_name: string }) => void>;
  }>({
    'alert:new': new Set(),
    'alert:updated': new Set(),
    'alert:expired': new Set(),
    'family:location': new Set(),
    'family:geofence_exit': new Set(),
  });

  useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('jwt_token') : null;
    if (!user || !token) {
      if (socketRef.current) {
        socketRef.current.disconnect();
        socketRef.current = null;
        setConnected(false);
      }
      return;
    }

    const socket = io(SOCKET_URL, {
      query: { token },
      transports: ['websocket'],
    });

    socket.on('connect', () => setConnected(true));
    socket.on('disconnect', () => setConnected(false));

    socket.on('alert:new', (data: Alert) => {
      listenersRef.current['alert:new'].forEach(cb => cb(data));
    });
    socket.on('alert:updated', (data: { id: string; confirms: number; denies: number }) => {
      listenersRef.current['alert:updated'].forEach(cb => cb(data));
    });
    socket.on('alert:expired', (data: { alert_id: string }) => {
      listenersRef.current['alert:expired'].forEach(cb => cb(data));
    });
    socket.on('family:location', (data: { user_id: string; lat: number; lng: number; recorded_at: string }) => {
      listenersRef.current['family:location'].forEach(cb => cb(data));
    });
    socket.on('family:geofence_exit', (data: { user_id: string; username: string; geofence_name: string }) => {
      listenersRef.current['family:geofence_exit'].forEach(cb => cb(data));
    });

    socketRef.current = socket;

    return () => {
      socket.disconnect();
      socketRef.current = null;
      setConnected(false);
    };
  }, [user]);

  const createListener = useCallback(<T,>(event: string) => {
    return (cb: (data: T) => void) => {
      const set = listenersRef.current[event as keyof typeof listenersRef.current] as Set<(data: T) => void>;
      set.add(cb);
      return () => { set.delete(cb); };
    };
  }, []);

  const updateLocation = useCallback((lat: number, lng: number) => {
    socketRef.current?.emit('location:update', { lat, lng });
  }, []);

  return (
    <SocketContext.Provider
      value={{
        connected,
        onNewAlert: createListener<Alert>('alert:new'),
        onAlertUpdated: createListener<{ id: string; confirms: number; denies: number }>('alert:updated'),
        onAlertExpired: createListener<{ alert_id: string }>('alert:expired'),
        onFamilyLocation: createListener<{ user_id: string; lat: number; lng: number; recorded_at: string }>('family:location'),
        onGeofenceExit: createListener<{ user_id: string; username: string; geofence_name: string }>('family:geofence_exit'),
        updateLocation,
      }}
    >
      {children}
    </SocketContext.Provider>
  );
}

export function useSocket() {
  const ctx = useContext(SocketContext);
  if (!ctx) throw new Error('useSocket must be used within SocketProvider');
  return ctx;
}
