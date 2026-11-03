'use client';
import { useApiResource } from '@/hooks/useApiResource';
import { asArray } from '@/lib/api';
import { PageHeader } from '@/components/layout/PageHeader';
import { ErrorState } from '@/components/ui/ErrorState';
import { EmptyState } from '@/components/ui/EmptyState';
import { Skeleton } from '@/components/ui/Skeleton';
type Post = {
  id: string;
  title: string;
  content?: string;
  image_url?: string;
  author_username?: string;
  created_at: string;
  category?: string;
};
export default function NewsPage() {
  const resource = useApiResource<{ posts: Post[] }>('/posts');
  const posts = asArray(resource.data?.posts);
  return (
    <div className="form-container space-y-4">
      <PageHeader title="Aktualności" description="Wiadomości i informacje od be:Safe." />
      {resource.loading && <Skeleton />}
      {resource.error && <ErrorState message={resource.error} onRetry={resource.reload} />}
      {!resource.loading && !resource.error && !posts.length && (
        <EmptyState
          title="Brak aktualności"
          description="Nowe wiadomości pojawią się w tym miejscu."
        />
      )}
      {posts.map((post) => (
        <article key={post.id} className="panel space-y-3">
          {post.category && <p className="text-sm text-primary">{post.category}</p>}
          <h2 className="text-xl font-bold">{post.title}</h2>
          <p className="text-sm text-ink-2">
            {post.author_username || 'be:Safe'} ·{' '}
            {new Date(post.created_at).toLocaleDateString('pl-PL')}
          </p>
          {post.image_url && (
            <img
              src={post.image_url}
              alt={`Ilustracja: ${post.title}`}
              className="w-full max-h-80 object-contain rounded-xl"
            />
          )}
          <p className="whitespace-pre-wrap break-words">
            {post.content || 'Brak dodatkowej treści.'}
          </p>
        </article>
      ))}
    </div>
  );
}
