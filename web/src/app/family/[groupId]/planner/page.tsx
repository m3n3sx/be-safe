'use client';

import React, { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';

interface FamilyEvent {
  id: string;
  title: string;
  description?: string | null;
  start_at: string;
  end_at?: string | null;
  location?: string | null;
  created_by: string;
  creator_username?: string;
}

export default function FamilyPlannerPage() {
  const params = useParams<{ groupId: string }>();
  const router = useRouter();
  const groupId = params.groupId;
  const [events, setEvents] = useState<FamilyEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startAt, setStartAt] = useState('');
  const [location, setLocation] = useState('');

  const load = async () => {
    setLoading(true);
    const res = await api.get<{ events: FamilyEvent[] }>(`/family/groups/${groupId}/events`);
    if (!res.error && res.events) setEvents(res.events);
    setLoading(false);
  };

  useEffect(() => { if (groupId) load(); }, [groupId]);

  const createEvent = async () => {
    if (!title.trim() || !startAt) return;
    const res = await api.post(`/family/groups/${groupId}/events`, {
      title, description, start_at: new Date(startAt).toISOString(), location,
    });
    if (!res.error) {
      setShowCreate(false);
      setTitle(''); setDescription(''); setStartAt(''); setLocation('');
      load();
    }
  };

  const remove = async (id: string) => {
    if (!confirm('Usunąć wydarzenie?')) return;
    await api.delete(`/family/groups/${groupId}/events/${id}`);
    load();
  };

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/family')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">📅 Planner rodzinny</h1>
        </div>

        <button
          onClick={() => setShowCreate(true)}
          className="mb-6 w-full py-3 rounded-2xl bg-[#1A2027] text-white font-medium"
        >+ Dodaj wydarzenie</button>

        {loading && <p className="text-center text-neutral-500">Ładowanie…</p>}
        {!loading && events.length === 0 && (
          <div className="text-center py-12 text-neutral-500">
            <p className="text-5xl mb-3">📅</p>
            <p>Brak wydarzeń.</p>
          </div>
        )}

        <div className="space-y-3">
          {events.map(e => (
            <div key={e.id} className="bg-white dark:bg-neutral-900 rounded-2xl p-4 border border-neutral-200 dark:border-neutral-800">
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="font-semibold text-lg">{e.title}</h3>
                  <p className="text-sm text-[#1A2027]/70 dark:text-white/70">
                    {new Date(e.start_at).toLocaleString('pl-PL', { dateStyle: 'short', timeStyle: 'short' })}
                  </p>
                  {e.location && <p className="text-sm text-neutral-500 mt-1">📍 {e.location}</p>}
                  {e.description && <p className="text-sm mt-2">{e.description}</p>}
                  {e.creator_username && <p className="text-xs text-neutral-400 mt-2">Utworzył: {e.creator_username}</p>}
                </div>
                <button onClick={() => remove(e.id)} className="text-red-500 text-sm">Usuń</button>
              </div>
            </div>
          ))}
        </div>

        {showCreate && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-neutral-900 rounded-2xl p-6 w-full max-w-md space-y-3">
              <h2 className="font-bold text-lg">Nowe wydarzenie</h2>
              <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Tytuł" className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" />
              <input type="datetime-local" value={startAt} onChange={e => setStartAt(e.target.value)} className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" />
              <input value={location} onChange={e => setLocation(e.target.value)} placeholder="Miejsce (opcjonalnie)" className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" />
              <textarea value={description} onChange={e => setDescription(e.target.value)} placeholder="Opis (opcjonalnie)" rows={3} className="w-full px-3 py-2 rounded-lg bg-neutral-100 dark:bg-neutral-800" />
              <div className="flex gap-2 justify-end pt-2">
                <button onClick={() => setShowCreate(false)} className="px-4 py-2">Anuluj</button>
                <button onClick={createEvent} disabled={!title.trim() || !startAt} className="px-4 py-2 rounded-lg bg-[#1A2027] text-white disabled:opacity-40">Utwórz</button>
              </div>
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
