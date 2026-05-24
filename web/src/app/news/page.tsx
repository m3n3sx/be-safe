'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import AppLayout from '@/components/ui/AppLayout';
import api from '@/lib/api';

interface CommunityPost {
  id: string;
  title: string;
  body?: string | null;
  author_username?: string;
  created_at: string;
  category?: string | null;
}

export default function NewsPage() {
  const router = useRouter();
  const [posts, setPosts] = useState<CommunityPost[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const res = await api.get<{ posts: CommunityPost[] }>('/community/posts');
      if (!res.error && res.posts) setPosts(res.posts);
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
        {!loading && posts.length === 0 && (
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
              {p.body && <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-2 whitespace-pre-wrap line-clamp-6">{p.body}</p>}
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
