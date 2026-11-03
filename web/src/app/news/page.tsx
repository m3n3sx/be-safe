'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';

interface CommunityPost {
  id: string;
  title: string;
  content?: string | null;
  image_url?: string | null;
  author_username?: string;
  created_at: string;
  category?: string | null;
}

export default function NewsPage() {
  const router = useRouter();
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      const res = await api.get<{ posts: CommunityPost[] }>('/posts');
      if (!res.error && res.posts) setPosts(res.posts);
      else setError('Nie udało się pobrać aktualności. Odśwież stronę, aby spróbować ponownie.');
      setLoading(false);
    })();
  }, []);

  return (
    <AppLayout>
      <div className="max-w-3xl mx-auto px-4 py-6">
        <div className="flex items-center gap-3 mb-6">
          <button onClick={() => router.push('/')} className="text-2xl">←</button>
          <h1 className="text-2xl font-bold">📰 Aktualności</h1>
        </div>

        {loading && <p className="text-neutral-500">Ładowanie…</p>}
        {error && <p role="alert" className="text-danger">{error}</p>}
        {!loading && !error && posts.length === 0 && (
          <div className="text-center py-12 text-neutral-500">
            <p className="text-5xl mb-3">📰</p>
            <p>Brak aktualności.</p>
          </div>
        )}

        <div className="space-y-3">
          {posts.map(p => (
            <article key={p.id} className="bg-white dark:bg-neutral-900 rounded-2xl border border-neutral-200 dark:border-neutral-800 p-5">
              {p.category && <span className="text-xs px-2 py-0.5 rounded-full bg-[#9DF4CB]/30 text-[#1A2027]">{p.category}</span>}
              <h2 className="font-semibold text-lg mt-1">{p.title}</h2>
              {p.image_url && <img src={p.image_url} alt={`Ilustracja: ${p.title}`} className="w-full max-h-80 object-contain rounded-xl my-3" />}
              {p.content && <p className="text-ink-2 mt-2 whitespace-pre-wrap">{p.content}</p>}
              <p className="text-xs text-neutral-400 mt-3">
                {p.author_username || 'be:Safe'} · {new Date(p.created_at).toLocaleString('pl-PL', { dateStyle: 'short', timeStyle: 'short' })}
              </p>
            </article>
          ))}
        </div>
      </div>
    </AppLayout>
  );
}
