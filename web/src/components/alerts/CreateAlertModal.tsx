'use client';

import React, { useState, useRef } from 'react';
import api from '@/lib/api';
import { t, getLang } from '@/lib/i18n';
import { DURATION_OPTIONS } from '@/lib/constants';
import { ALERT_CATEGORIES } from '@/types';
import type { Alert, AlertCategory, AlertCategoryInfo } from '@/types';

interface Props {
  position: { lat: number; lng: number };
  onClose: () => void;
  onCreated: (alert: Alert) => void;
}

// Need ALERT_CATEGORIES from types, not constants
import { ALERT_CATEGORIES as CATEGORIES } from '@/types';

export default function CreateAlertModal({ position, onClose, onCreated }: Props) {
  const [step, setStep] = useState<'category' | 'details'>('category');
  const [category, setCategory] = useState<AlertCategory | null>(null);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [duration, setDuration] = useState(3);
  const [photo, setPhoto] = useState<File | null>(null);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileRef = useRef<HTMLInputElement>(null);
  const lang = getLang();

  const handlePhotoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setPhoto(file);
      const reader = new FileReader();
      reader.onload = () => setPhotoPreview(reader.result as string);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async () => {
    if (!category || !title.trim()) return;
    setLoading(true);
    setError(null);

    // Create alert
    const res = await api.post<Alert>('/alerts', {
      category,
      title: title.trim(),
      description: description.trim() || undefined,
      lat: position.lat,
      lng: position.lng,
      duration_hours: duration,
    });

    if (res.error) {
      setError(res.error);
      setLoading(false);
      return;
    }

    const alert = res as Alert;

    // Upload photo if exists
    if (photo && alert.id) {
      const formData = new FormData();
      formData.append('photo', photo);
      await api.multipart(`/alerts/${alert.id}/photo`, formData);
    }

    onCreated(alert);
    setLoading(false);
  };

  return (
    <div className="absolute inset-0 z-40 flex items-end sm:items-center justify-center">
      <div className="absolute inset-0 bg-black/40" onClick={onClose} />
      <div className="relative w-full sm:max-w-lg max-h-[85vh] bg-white dark:bg-neutral-900 sm:rounded-2xl rounded-t-2xl border border-neutral-200 dark:border-neutral-800 shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-neutral-200 dark:border-neutral-800">
          <h2 className="text-lg font-bold text-neutral-900 dark:text-white">{t('report')}</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-500">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto px-5 py-4">
          {step === 'category' ? (
            <div className="space-y-4">
              <p className="text-sm text-neutral-500">{t('category')}</p>
              <div className="grid grid-cols-2 gap-2">
                {CATEGORIES.map(cat => (
                  <button
                    key={cat.key}
                    onClick={() => { setCategory(cat.key); setStep('details'); setTitle(lang === 'en' ? cat.labelEn : cat.label); }}
                    className="flex items-center gap-2 px-3 py-3 rounded-xl border border-neutral-200 dark:border-neutral-800 text-left text-sm hover:bg-neutral-50 dark:hover:bg-neutral-800 hover:border-red-500/30 transition-colors"
                  >
                    <span className="text-xl">{cat.emoji}</span>
                    <span className="text-neutral-900 dark:text-white font-medium">
                      {lang === 'en' ? cat.labelEn : cat.label}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              {/* Selected category */}
              {category && (
                <button
                  onClick={() => setStep('category')}
                  className="flex items-center gap-2 text-sm text-red-500 hover:underline"
                >
                  <span>&larr;</span>
                  <span>{getCatInfo(category)?.emoji} {lang === 'en' ? getCatInfo(category)?.labelEn : getCatInfo(category)?.label}</span>
                </button>
              )}

              {error && (
                <div className="px-4 py-3 rounded-xl bg-red-500/10 border border-red-500/20 text-red-500 text-sm">
                  {error}
                </div>
              )}

              {/* Title */}
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
                  {t('title')} *
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={e => setTitle(e.target.value)}
                  required
                  maxLength={100}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm text-neutral-900 dark:text-white focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500"
                />
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
                  {t('description')}
                </label>
                <textarea
                  value={description}
                  onChange={e => setDescription(e.target.value)}
                  rows={3}
                  className="w-full rounded-xl border border-neutral-300 dark:border-neutral-700 bg-neutral-50 dark:bg-neutral-800 px-4 py-2.5 text-sm text-neutral-900 dark:text-white focus:border-red-500 focus:outline-none focus:ring-1 focus:ring-red-500 resize-none"
                />
              </div>

              {/* Duration */}
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
                  {t('duration')}
                </label>
                <div className="flex gap-2">
                  {DURATION_OPTIONS.map(opt => (
                    <button
                      key={opt.value}
                      onClick={() => setDuration(opt.value)}
                      className={`flex-1 py-2 rounded-xl text-sm font-medium transition-colors ${
                        duration === opt.value
                          ? 'bg-red-500 text-white'
                          : 'bg-neutral-100 dark:bg-neutral-800 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-200 dark:hover:bg-neutral-700'
                      }`}
                    >
                      {opt.label}
                    </button>
                  ))}
                </div>
              </div>

              {/* Photo */}
              <div>
                <label className="block text-sm font-medium text-neutral-700 dark:text-neutral-300 mb-1.5">
                  {t('photo')}
                </label>
                <input type="file" ref={fileRef} accept="image/*" onChange={handlePhotoChange} className="hidden" />
                {photoPreview ? (
                  <div className="relative">
                    <img src={photoPreview} alt="Preview" className="w-full h-40 object-cover rounded-xl" />
                    <button
                      onClick={() => { setPhoto(null); setPhotoPreview(null); }}
                      className="absolute top-2 right-2 p-1 rounded-full bg-black/50 text-white"
                    >
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => fileRef.current?.click()}
                    className="w-full py-6 rounded-xl border-2 border-dashed border-neutral-300 dark:border-neutral-700 text-neutral-500 text-sm hover:border-red-500/50 hover:text-red-500 transition-colors"
                  >
                    {t('add_photo')}
                  </button>
                )}
              </div>

              {/* Location */}
              <div className="bg-neutral-50 dark:bg-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-500">
                {t('selected_location')}: {position.lat.toFixed(5)}, {position.lng.toFixed(5)}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        {step === 'details' && (
          <div className="px-5 py-4 border-t border-neutral-200 dark:border-neutral-800">
            <button
              onClick={handleSubmit}
              disabled={loading || !title.trim() || !category}
              className="w-full py-3 rounded-xl bg-red-500 text-white font-medium text-sm hover:bg-red-600 disabled:opacity-50 transition-colors"
            >
              {loading ? t('loading') : t('send')}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

function getCatInfo(key: AlertCategory): AlertCategoryInfo | undefined {
  return CATEGORIES.find(c => c.key === key);
}
