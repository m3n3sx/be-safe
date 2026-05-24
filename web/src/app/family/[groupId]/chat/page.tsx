'use client';

import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';
import { useSocket, type FamilyMessage } from '@/contexts/SocketContext';
import { useAuth } from '@/contexts/AuthContext';

export default function FamilyChatPage() {
  const params = useParams<{ groupId: string }>();
  const router = useRouter();
  const { user } = useAuth();
  const { onFamilyMessage } = useSocket();
  const groupId = params.groupId;
  const [messages, setMessages] = useState<FamilyMessage[]>([]);
  const [body, setBody] = useState('');
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [groupName, setGroupName] = useState('');
  const listRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback(() => {
    requestAnimationFrame(() => {
      if (listRef.current) listRef.current.scrollTop = listRef.current.scrollHeight;
    });
  }, []);

  useEffect(() => {
    if (!groupId) return;
    (async () => {
      setLoading(true);
      const res = await api.get<{ messages: FamilyMessage[] }>(`/family/groups/${groupId}/messages?limit=100`);
      if (!res.error && res.messages) setMessages(res.messages);
      const g = await api.get<{ groups: { id: string; name: string }[] }>('/family/groups');
      if (!g.error && g.groups) {
        const found = g.groups.find(x => x.id === groupId);
        if (found) setGroupName(found.name);
      }
      setLoading(false);
      scrollToBottom();
    })();
  }, [groupId, scrollToBottom]);

  useEffect(() => {
    const off = onFamilyMessage((msg) => {
      if (msg.group_id !== groupId) return;
      setMessages(prev => [...prev, msg]);
      scrollToBottom();
    });
    return off;
  }, [onFamilyMessage, groupId, scrollToBottom]);

  const send = async () => {
    const text = body.trim();
    if (!text || sending) return;
    setSending(true);
    const res = await api.post<FamilyMessage>(`/family/groups/${groupId}/messages`, { body: text });
    setSending(false);
    if (!res.error && res.id) {
      setMessages(prev => [...prev, res as FamilyMessage]);
      setBody('');
      scrollToBottom();
    }
  };

  return (
    <AppLayout>
      <div className="flex flex-col h-[calc(100vh-80px)] max-w-4xl mx-auto">
        <div className="px-4 py-3 border-b border-neutral-200 dark:border-neutral-800 flex items-center gap-3">
          <button onClick={() => router.push('/family')} className="text-2xl">←</button>
          <div>
            <h1 className="font-semibold text-lg">💬 {groupName || 'Czat'}</h1>
            <p className="text-xs text-neutral-500">{messages.length} wiadomości</p>
          </div>
        </div>

        <div ref={listRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-2">
          {loading && <p className="text-center text-neutral-500">Ładowanie…</p>}
          {!loading && messages.length === 0 && (
            <div className="text-center py-12 text-neutral-500">
              <p className="text-4xl mb-2">💬</p>
              <p>Brak wiadomości. Napisz pierwszą.</p>
            </div>
          )}
          {messages.map(m => {
            const mine = m.author_id === user?.id;
            return (
              <div key={m.id} className={`flex ${mine ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[75%] rounded-2xl px-4 py-2 ${mine ? 'bg-[#9DF4CB] text-[#1A2027]' : 'bg-neutral-200 dark:bg-neutral-800'}`}>
                  {!mine && <p className="text-xs font-semibold text-[#1A2027]/70 dark:text-white/70">{m.author_username}</p>}
                  <p className="whitespace-pre-wrap break-words">{m.body}</p>
                  <p className="text-[10px] mt-1 opacity-60">{new Date(m.created_at).toLocaleTimeString('pl-PL', { hour: '2-digit', minute: '2-digit' })}</p>
                </div>
              </div>
            );
          })}
        </div>

        <div className="px-4 py-3 border-t border-neutral-200 dark:border-neutral-800 flex gap-2">
          <input
            value={body}
            onChange={e => setBody(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }}
            placeholder="Napisz wiadomość…"
            maxLength={2000}
            className="flex-1 rounded-full px-4 py-2 bg-neutral-100 dark:bg-neutral-800 outline-none focus:ring-2 focus:ring-[#9DF4CB]"
          />
          <button
            onClick={send}
            disabled={!body.trim() || sending}
            className="px-5 py-2 rounded-full bg-[#1A2027] text-white disabled:opacity-40"
          >Wyślij</button>
        </div>
      </div>
    </AppLayout>
  );
}
