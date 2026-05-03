'use client';

import React, { useState, useEffect } from 'react';
import api from '@/lib/api';
import { t, getLang } from '@/lib/i18n';
import type { Alert, AlertComment } from '@/types';
import { getCategoryInfo } from '@/types';
import { useAuth } from '@/contexts/AuthContext';

interface Props {
  alert: Alert;
  onClose: () => void;
  onUpdate: (alert: Alert) => void;
  onDelete: (id: string) => void;
}

export default function AlertDetail({ alert, onClose, onUpdate, onDelete }: Props) {
  const { user } = useAuth();
  const [comments, setComments] = useState<AlertComment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [loading, setLoading] = useState(false);
  const [voting, setVoting] = useState(false);
  const [editDesc, setEditDesc] = useState(false);
  const [description, setDescription] = useState(alert.description || '');

  const cat = getCategoryInfo(alert.category);
  const isOwner = user?.id === alert.author_id;
  const lang = getLang();

  useEffect(() => {
    loadComments();
  }, [alert.id]);

  const loadComments = async () => {
    const res = await api.get<{ comments: AlertComment[] }>(`/alerts/${alert.id}/comments`);
    if (!res.error && res.comments) setComments(res.comments);
  };

  const handleVote = async (type: 'confirm' | 'deny') => {
    setVoting(true);
    const res = await api.post<Alert>(`/alerts/${alert.id}/vote`, { vote: type });
    if (!res.error) {
      onUpdate(res as Alert);
    }
    setVoting(false);
  };

  const handleComment = async () => {
    if (!newComment.trim()) return;
    setLoading(true);
    const res = await api.post<AlertComment>(`/alerts/${alert.id}/comments`, { content: newComment });
    if (!res.error) {
      setComments(prev => [...prev, res as AlertComment]);
      setNewComment('');
    }
    setLoading(false);
  };

  const handleExtend = async () => {
    const res = await api.patch<Alert>(`/alerts/${alert.id}`, { extend_hours: 3 });
    if (!res.error) onUpdate(res as Alert);
  };

  const handleUpdateDesc = async () => {
    const res = await api.patch<Alert>(`/alerts/${alert.id}`, { description });
    if (!res.error) {
      onUpdate(res as Alert);
      setEditDesc(false);
    }
  };

  const handleDelete = async () => {
    if (!confirm(t('delete_confirm'))) return;
    const res = await api.delete(`/alerts/${alert.id}`);
    if (!res.error) onDelete(alert.id);
  };

  const timeAgo = (date: string) => {
    const diff = Date.now() - new Date(date).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 60) return `${mins} ${t('min')} ${t('ago')}`;
    const hrs = Math.floor(mins / 60);
    return `${hrs}h ${t('ago')}`;
  };

  const credibility = alert.confirms + alert.denies > 0
    ? Math.round((alert.confirms / (alert.confirms + alert.denies)) * 100)
    : 50;

  return (
    <div className="absolute top-0 right-0 z-30 h-full w-full sm:w-96 bg-white dark:bg-neutral-900 border-l border-neutral-200 dark:border-neutral-800 shadow-2xl flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-neutral-200 dark:border-neutral-800">
        <div className="flex items-center gap-2">
          <span className="text-xl">{cat.emoji}</span>
          <span className="font-medium text-neutral-900 dark:text-white text-sm">
            {lang === 'en' ? cat.labelEn : cat.label}
          </span>
        </div>
        <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-500">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {/* Title and description */}
        <div>
          <h2 className="text-lg font-bold text-neutral-900 dark:text-white">{alert.title}</h2>
          {editDesc ? (
            <div className="mt-2 space-y-2">
              <textarea
                value={description}
                onChange={e => setDescription(e.target.value)}
                className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-3 py-2 text-sm resize-none h-20"
              />
              <div className="flex gap-2">
                <button onClick={handleUpdateDesc} className="px-3 py-1.5 rounded-lg bg-red-500 text-white text-xs font-medium">{t('save')}</button>
                <button onClick={() => setEditDesc(false)} className="px-3 py-1.5 rounded-lg bg-neutral-200 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 text-xs">{t('cancel')}</button>
              </div>
            </div>
          ) : (
            <p className="text-sm text-neutral-600 dark:text-neutral-400 mt-1">{alert.description}</p>
          )}
        </div>

        {/* Photo */}
        {alert.photo_url && (
          <img
            src={alert.photo_url}
            alt={alert.title}
            className="w-full rounded-xl object-cover max-h-48"
          />
        )}

        {/* Meta info */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2">
            <p className="text-[10px] uppercase tracking-wider text-neutral-500 mb-0.5">{t('created')}</p>
            <p className="text-sm font-medium text-neutral-900 dark:text-white">{timeAgo(alert.created_at)}</p>
          </div>
          <div className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2">
            <p className="text-[10px] uppercase tracking-wider text-neutral-500 mb-0.5">{t('expires')}</p>
            <p className="text-sm font-medium text-neutral-900 dark:text-white">{timeAgo(alert.expires_at)}</p>
          </div>
          <div className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2">
            <p className="text-[10px] uppercase tracking-wider text-neutral-500 mb-0.5">{t('credibility')}</p>
            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 rounded-full bg-neutral-200 dark:bg-neutral-700 overflow-hidden">
                <div className="h-full rounded-full bg-green-500" style={{ width: `${credibility}%` }} />
              </div>
              <span className="text-xs font-medium text-neutral-900 dark:text-white">{credibility}%</span>
            </div>
          </div>
          {alert.distance_m !== undefined && (
            <div className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2">
              <p className="text-[10px] uppercase tracking-wider text-neutral-500 mb-0.5">{t('distance')}</p>
              <p className="text-sm font-medium text-neutral-900 dark:text-white">
                {alert.distance_m > 1000 ? `${(alert.distance_m / 1000).toFixed(1)} km` : `${Math.round(alert.distance_m)} m`}
              </p>
            </div>
          )}
        </div>

        {/* Vote buttons */}
        <div className="flex gap-2">
          <button
            onClick={() => handleVote('confirm')}
            disabled={voting}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-green-500/10 text-green-600 dark:text-green-400 font-medium text-sm hover:bg-green-500/20 transition-colors disabled:opacity-50"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
            {t('confirm_alert')} ({alert.confirms})
          </button>
          <button
            onClick={() => handleVote('deny')}
            disabled={voting}
            className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-red-500/10 text-red-500 font-medium text-sm hover:bg-red-500/20 transition-colors disabled:opacity-50"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
            {t('deny_alert')} ({alert.denies})
          </button>
        </div>

        {/* Owner actions */}
        {isOwner && (
          <div className="flex gap-2">
            <button onClick={handleExtend} className="flex-1 py-2 rounded-xl bg-blue-500/10 text-blue-500 text-sm font-medium hover:bg-blue-500/20 transition-colors">
              {t('extend')}
            </button>
            <button onClick={() => setEditDesc(true)} className="flex-1 py-2 rounded-xl bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 text-sm font-medium hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors">
              {t('edit_description')}
            </button>
            <button onClick={handleDelete} className="py-2 px-3 rounded-xl bg-red-500/10 text-red-500 text-sm font-medium hover:bg-red-500/20 transition-colors">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        )}

        {/* Author */}
        <div className="flex items-center gap-2 text-sm text-neutral-500">
          <span>{t('author')}:</span>
          <span className="font-medium text-neutral-700 dark:text-neutral-300">{alert.author_username || 'Unknown'}</span>
        </div>

        {/* Comments */}
        <div>
          <h3 className="text-sm font-medium text-neutral-900 dark:text-white mb-3">
            {t('comments')} ({comments.length})
          </h3>
          <div className="space-y-2 mb-3">
            {comments.map(c => (
              <div key={c.id} className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-medium text-neutral-700 dark:text-neutral-300">{c.username}</span>
                  <span className="text-[10px] text-neutral-500">{timeAgo(c.created_at)}</span>
                </div>
                <p className="text-sm text-neutral-600 dark:text-neutral-400">{c.content}</p>
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              type="text"
              value={newComment}
              onChange={e => setNewComment(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleComment()}
              placeholder={t('add_comment')}
              className="flex-1 rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-3 py-2 text-sm focus:border-red-500 focus:outline-none"
            />
            <button
              onClick={handleComment}
              disabled={loading || !newComment.trim()}
              className="px-4 py-2 rounded-xl bg-red-500 text-white text-sm font-medium hover:bg-red-600 disabled:opacity-50 transition-colors"
            >
              {t('send')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
