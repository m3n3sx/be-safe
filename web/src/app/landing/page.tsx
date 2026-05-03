'use client';

import React, { useEffect, useState, useRef } from 'react';

// ─── Animated counter ───────────────────────────────────────
function AnimatedNumber({ target, suffix = '' }: { target: number; suffix?: string }) {
  const [count, setCount] = useState(0);
  const ref = useRef<HTMLSpanElement>(null);
  const started = useRef(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !started.current) {
          started.current = true;
          const duration = 1500;
          const steps = 40;
          const increment = target / steps;
          let current = 0;
          const timer = setInterval(() => {
            current += increment;
            if (current >= target) {
              setCount(target);
              clearInterval(timer);
            } else {
              setCount(Math.floor(current));
            }
          }, duration / steps);
        }
      },
      { threshold: 0.5 }
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, [target]);

  return <span ref={ref}>{count}{suffix}</span>;
}

// ─── Fade-in on scroll ──────────────────────────────────────
function FadeIn({ children, className = '', delay = 0 }: { children: React.ReactNode; className?: string; delay?: number }) {
  const ref = useRef<HTMLDivElement>(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setVisible(true); },
      { threshold: 0.15 }
    );
    if (ref.current) observer.observe(ref.current);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      className={`transition-all duration-700 ${visible ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-8'} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </div>
  );
}

// ─── Category badge ─────────────────────────────────────────
const CATEGORIES = [
  { key: 'aggression', emoji: '👊', label: 'Agresja', color: '#EF4444' },
  { key: 'theft', emoji: '🦹', label: 'Kradzież', color: '#F97316' },
  { key: 'accident', emoji: '🚗', label: 'Wypadek', color: '#EAB308' },
  { key: 'fire', emoji: '🔥', label: 'Pożar', color: '#DC2626' },
  { key: 'flood', emoji: '🌊', label: 'Powódź', color: '#3B82F6' },
  { key: 'ice', emoji: '🧊', label: 'Oblodzenie', color: '#06B6D4' },
  { key: 'construction', emoji: '🚧', label: 'Budowa', color: '#F59E0B' },
  { key: 'animal', emoji: '🐕', label: 'Zwierzę', color: '#84CC16' },
  { key: 'dark_area', emoji: '🌑', label: 'Ciemna strefa', color: '#6B7280' },
  { key: 'drugs', emoji: '💊', label: 'Narkotyki', color: '#8B5CF6' },
  { key: 'police', emoji: '🚔', label: 'Policja', color: '#2563EB' },
  { key: 'weather', emoji: '⛈️', label: 'Pogoda', color: '#0EA5E9' },
  { key: 'other', emoji: '⚠️', label: 'Inne', color: '#A3A3A3' },
  { key: 'stranger_danger', emoji: '🚸', label: 'Obcy przy dziecku', color: '#E11D48' },
  { key: 'traffic_danger', emoji: '🚦', label: 'Ruch drogowy', color: '#EA580C' },
  { key: 'playground_hazard', emoji: '🛝', label: 'Plac zabaw', color: '#16A34A' },
  { key: 'water_hazard', emoji: '💧', label: 'Woda', color: '#0284C7' },
  { key: 'school_zone', emoji: '🏫', label: 'Strefa szkolna', color: '#7C3AED' },
];

// ─── Feature card ───────────────────────────────────────────
function FeatureCard({ icon, title, description, delay }: { icon: React.ReactNode; title: string; description: string; delay: number }) {
  return (
    <FadeIn delay={delay}>
      <div className="group relative rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-6 hover:border-red-300 dark:hover:border-red-800 hover:shadow-lg hover:shadow-red-500/5 transition-all duration-300">
        <div className="w-12 h-12 rounded-xl bg-red-50 dark:bg-red-950 flex items-center justify-center text-red-500 mb-4 group-hover:scale-110 transition-transform">
          {icon}
        </div>
        <h3 className="text-lg font-semibold text-neutral-900 dark:text-white mb-2">{title}</h3>
        <p className="text-sm text-neutral-600 dark:text-neutral-400 leading-relaxed">{description}</p>
      </div>
    </FadeIn>
  );
}

// ─── Main Landing Page ──────────────────────────────────────
export default function LandingPage() {
  const [darkMode, setDarkMode] = useState(false);

  useEffect(() => {
    const isDark = document.documentElement.classList.contains('dark') ||
      window.matchMedia('(prefers-color-scheme: dark)').matches;
    setDarkMode(isDark);
  }, []);

  return (
    <div className="min-h-screen bg-white dark:bg-neutral-950 text-neutral-900 dark:text-white overflow-x-hidden">
      {/* ═══════════ NAVBAR ═══════════ */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-white/80 dark:bg-neutral-950/80 backdrop-blur-xl border-b border-neutral-100 dark:border-neutral-900">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-red-500 flex items-center justify-center">
              <span className="text-white font-bold text-sm">b:S</span>
            </div>
            <span className="font-bold text-lg tracking-tight">be:Safe</span>
          </div>
          <div className="hidden md:flex items-center gap-8 text-sm text-neutral-600 dark:text-neutral-400">
            <a href="#features" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Funkcje</a>
            <a href="#family" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Rodzina</a>
            <a href="#categories" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Kategorie</a>
            <a href="#stats" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Statystyki</a>
          </div>
          <div className="flex items-center gap-3">
            <a
              href="/"
              className="hidden sm:inline-flex text-sm font-medium text-neutral-600 dark:text-neutral-400 hover:text-neutral-900 dark:hover:text-white transition-colors"
            >
              Zaloguj się
            </a>
            <a
              href="https://alert.u235.pl/api/v1/download"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-red-500 text-white text-sm font-medium hover:bg-red-600 transition-colors shadow-lg shadow-red-500/20"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" /></svg>
              Pobierz APK
            </a>
          </div>
        </div>
      </nav>

      {/* ═══════════ HERO ═══════════ */}
      <section className="relative pt-32 pb-20 sm:pt-40 sm:pb-32 px-4 sm:px-6">
        {/* Background gradient */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[600px] bg-gradient-to-b from-red-500/8 via-transparent to-transparent rounded-full blur-3xl" />
          <div className="absolute top-20 right-0 w-[400px] h-[400px] bg-gradient-to-bl from-orange-500/5 to-transparent rounded-full blur-3xl" />
        </div>

        <div className="relative max-w-4xl mx-auto text-center">
          <FadeIn>
            <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-red-50 dark:bg-red-950/50 border border-red-200 dark:border-red-900 text-red-600 dark:text-red-400 text-sm font-medium mb-8">
              <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
              Działająca w czasie rzeczywistym
            </div>
          </FadeIn>

          <FadeIn delay={100}>
            <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-extrabold tracking-tight leading-[1.1] mb-6">
              Wiedz o zagrożeniach{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-red-500 via-red-500 to-orange-500">
                zanim do Ciebie dotrą
              </span>
            </h1>
          </FadeIn>

          <FadeIn delay={200}>
            <p className="text-lg sm:text-xl text-neutral-600 dark:text-neutral-400 max-w-2xl mx-auto mb-10 leading-relaxed">
              Społecznościowy system ostrzegania w czasie rzeczywistym. Zgłaszaj i monitoruj
              zagrożenia w swojej okolicy. Chroń siebie i swoją rodzinę.
            </p>
          </FadeIn>

          <FadeIn delay={300}>
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
              <a
                href="https://alert.u235.pl/api/v1/download"
                className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-red-500 text-white font-semibold text-lg hover:bg-red-600 transition-all shadow-xl shadow-red-500/25 hover:shadow-red-500/40 hover:scale-[1.02] active:scale-[0.98]"
              >
                <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M17.523 2.152a.5.5 0 00-.378-.103l-.104.024-5.04 1.48-5.042-1.48a.5.5 0 00-.584.29l-.03.092L3.002 12l3.343 9.545a.5.5 0 00.41.335l.094.005.078-.009 5.073-1.49 5.073 1.49a.5.5 0 00.585-.289l.03-.092L21 12l-3.344-9.545a.5.5 0 00-.133-.303zM12 4.69l4.283 1.258L12 7.808 7.717 5.948 12 4.69zm-4.5 2.556L12 9.412l4.5-2.166L19.673 12l-3.173 4.754L12 14.588l-4.5 2.166L4.327 12l3.173-4.754zM7.717 18.052L12 16.192l4.283 1.86L12 19.31l-4.283-1.258z"/></svg>
                Pobierz na Android
              </a>
              <a
                href="/"
                className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-neutral-100 dark:bg-neutral-900 text-neutral-900 dark:text-white font-semibold text-lg hover:bg-neutral-200 dark:hover:bg-neutral-800 transition-all border border-neutral-200 dark:border-neutral-800"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" /></svg>
                Otwórz wersję web
              </a>
            </div>
          </FadeIn>

          {/* Floating category pills */}
          <FadeIn delay={500}>
            <div className="mt-16 flex flex-wrap justify-center gap-2 max-w-2xl mx-auto">
              {CATEGORIES.slice(0, 10).map((cat, i) => (
                <span
                  key={cat.label}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 text-sm text-neutral-700 dark:text-neutral-300"
                  style={{ animationDelay: `${i * 100}ms` }}
                >
                  <span>{cat.emoji}</span>
                  {cat.label}
                </span>
              ))}
              <span className="inline-flex items-center px-3 py-1.5 rounded-full bg-neutral-100 dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 text-sm text-neutral-500">
                +8 więcej
              </span>
            </div>
          </FadeIn>
        </div>
      </section>

      {/* ═══════════ MOCKUP / MAP PREVIEW ═══════════ */}
      <section className="relative px-4 sm:px-6 pb-20 sm:pb-32">
        <FadeIn>
          <div className="max-w-5xl mx-auto">
            <div className="relative rounded-2xl overflow-hidden border border-neutral-200 dark:border-neutral-800 shadow-2xl shadow-neutral-900/10 dark:shadow-black/40">
              {/* Browser chrome */}
              <div className="bg-neutral-100 dark:bg-neutral-900 border-b border-neutral-200 dark:border-neutral-800 px-4 py-3 flex items-center gap-3">
                <div className="flex gap-1.5">
                  <div className="w-3 h-3 rounded-full bg-red-400" />
                  <div className="w-3 h-3 rounded-full bg-yellow-400" />
                  <div className="w-3 h-3 rounded-full bg-green-400" />
                </div>
                <div className="flex-1 bg-white dark:bg-neutral-800 rounded-lg px-3 py-1 text-xs text-neutral-500 text-center">
                  alert.u235.pl
                </div>
              </div>
              {/* Map mockup */}
              <div className="relative bg-neutral-200 dark:bg-neutral-800 aspect-[16/9] sm:aspect-[2/1] flex items-center justify-center overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-br from-green-100 via-green-50 to-blue-50 dark:from-neutral-900 dark:via-neutral-850 dark:to-neutral-900 opacity-80" />
                {/* Simulated map grid */}
                <div className="absolute inset-0 opacity-10 dark:opacity-5" style={{
                  backgroundImage: `linear-gradient(rgba(0,0,0,.1) 1px, transparent 1px), linear-gradient(90deg, rgba(0,0,0,.1) 1px, transparent 1px)`,
                  backgroundSize: '40px 40px'
                }} />
                {/* Simulated roads */}
                <div className="absolute top-1/2 left-0 right-0 h-[2px] bg-neutral-300 dark:bg-neutral-700 opacity-50" />
                <div className="absolute top-0 bottom-0 left-1/3 w-[2px] bg-neutral-300 dark:bg-neutral-700 opacity-50" />
                <div className="absolute top-0 bottom-0 right-1/4 w-[2px] bg-neutral-300 dark:bg-neutral-700 opacity-50" />
                <div className="absolute top-1/4 left-0 right-0 h-[1px] bg-neutral-300 dark:bg-neutral-700 opacity-30 rotate-6" />

                {/* Scattered markers */}
                {[
                  { top: '25%', left: '20%', emoji: '👊', color: '#EF4444' },
                  { top: '40%', left: '55%', emoji: '🚗', color: '#EAB308' },
                  { top: '60%', left: '35%', emoji: '🔥', color: '#DC2626' },
                  { top: '30%', left: '70%', emoji: '🚧', color: '#F59E0B' },
                  { top: '55%', left: '75%', emoji: '🐕', color: '#84CC16' },
                  { top: '70%', left: '15%', emoji: '🚔', color: '#2563EB' },
                  { top: '20%', left: '45%', emoji: '⛈️', color: '#0EA5E9' },
                  { top: '75%', left: '55%', emoji: '🦹', color: '#F97316' },
                ].map((m, i) => (
                  <div
                    key={i}
                    className="absolute flex flex-col items-center animate-bounce"
                    style={{ top: m.top, left: m.left, animationDelay: `${i * 200}ms`, animationDuration: '3s' }}
                  >
                    <div className="relative">
                      <svg width="36" height="44" viewBox="0 0 40 48">
                        <path d="M20 48s-1-1-1-1C18 46 2 30 2 18 2 8.1 10.1 0 20 0s18 8.1 18 18c0 12-16 28-17 29l-1 1z" fill={m.color} opacity="0.9"/>
                        <circle cx="20" cy="18" r="14" fill="white" opacity="0.95"/>
                        <text x="20" y="24" textAnchor="middle" fontSize="16">{m.emoji}</text>
                      </svg>
                    </div>
                  </div>
                ))}

                {/* User location dot */}
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
                  <div className="relative">
                    <div className="w-4 h-4 rounded-full bg-blue-500 border-[3px] border-white shadow-lg" />
                    <div className="absolute inset-0 w-4 h-4 rounded-full bg-blue-500 animate-ping opacity-30" />
                  </div>
                </div>

                {/* SOS Button mock */}
                <div className="absolute bottom-4 left-4 w-14 h-14 rounded-full bg-red-500 flex items-center justify-center shadow-xl shadow-red-500/30">
                  <span className="text-white font-extrabold text-sm">SOS</span>
                </div>

                {/* Report button mock */}
                <div className="absolute bottom-4 right-4 flex items-center gap-2 px-4 py-2.5 rounded-2xl bg-red-500 text-white text-sm font-medium shadow-xl">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" /></svg>
                  Zgłoś
                </div>
              </div>
            </div>
          </div>
        </FadeIn>
      </section>

      {/* ═══════════ FEATURES ═══════════ */}
      <section id="features" className="px-4 sm:px-6 py-20 sm:py-32">
        <div className="max-w-6xl mx-auto">
          <FadeIn>
            <div className="text-center mb-16">
              <span className="text-sm font-semibold text-red-500 uppercase tracking-wider">Funkcje</span>
              <h2 className="text-3xl sm:text-4xl font-bold mt-3 mb-4">Wszystko, czego potrzebujesz</h2>
              <p className="text-neutral-600 dark:text-neutral-400 max-w-xl mx-auto">
                Kompleksowy system bezpieczeństwa łączący społecznościowe zgłaszanie zagrożeń
                z modułem ochrony rodziny.
              </p>
            </div>
          </FadeIn>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            <FeatureCard
              delay={0}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>}
              title="Mapa zagrożeń w real-time"
              description="Zagrożenia pojawiają się na mapie natychmiast po zgłoszeniu. WebSocket zapewnia aktualizacje bez opóźnień."
            />
            <FeatureCard
              delay={100}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" /></svg>}
              title="18 kategorii zagrożeń"
              description="Od agresji i kradzieży, przez wypadki i pożary, po zagrożenia specyficzne dla dzieci. Każda z unikalną ikoną."
            />
            <FeatureCard
              delay={200}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>}
              title="System głosowania"
              description="Społeczność weryfikuje zgłoszenia. Potwierdź lub zaprzecz — alerty z niską wiarygodnością są automatycznie ukrywane."
            />
            <FeatureCard
              delay={300}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>}
              title="Powiadomienia push"
              description="Natychmiastowe alerty o nowych zagrożeniach w Twojej okolicy. Konfigurowalno promień od 100m do 5km."
            />
            <FeatureCard
              delay={400}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>}
              title="Zdjęcia zagrożeń"
              description="Dołącz zdjęcie do zgłoszenia — aparat lub galeria. Automatyczna optymalizacja do 1280px."
            />
            <FeatureCard
              delay={500}
              icon={<svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" /></svg>}
              title="Komentarze"
              description="Dyskutuj pod zgłoszeniami, dodawaj informacje, ostrzegaj innych. Buduj lokalną społeczność bezpieczeństwa."
            />
          </div>
        </div>
      </section>

      {/* ═══════════ SOS SECTION ═══════════ */}
      <section className="px-4 sm:px-6 py-20 sm:py-32 bg-gradient-to-b from-red-50 to-transparent dark:from-red-950/20 dark:to-transparent">
        <div className="max-w-5xl mx-auto">
          <div className="flex flex-col md:flex-row items-center gap-12 md:gap-16">
            <FadeIn className="flex-shrink-0">
              <div className="relative">
                <div className="w-32 h-32 sm:w-40 sm:h-40 rounded-full bg-red-500 flex items-center justify-center shadow-2xl shadow-red-500/30">
                  <span className="text-white font-black text-4xl sm:text-5xl">SOS</span>
                </div>
                <div className="absolute inset-0 w-32 h-32 sm:w-40 sm:h-40 rounded-full bg-red-500 animate-ping opacity-10" />
                <div className="absolute -inset-4 rounded-full border-2 border-red-300 dark:border-red-800 opacity-50 animate-pulse" />
              </div>
            </FadeIn>
            <FadeIn delay={200}>
              <div>
                <h2 className="text-3xl sm:text-4xl font-bold mb-4">
                  Przycisk <span className="text-red-500">SOS</span>
                </h2>
                <p className="text-lg text-neutral-600 dark:text-neutral-400 leading-relaxed mb-6">
                  Jedno kliknięcie w sytuacji zagrożenia. Automatycznie wysyła alert z Twoją
                  dokładną lokalizacją GPS do wszystkich użytkowników w okolicy. Bez zbędnych
                  formularzy — liczy się każda sekunda.
                </p>
                <div className="flex flex-wrap gap-3">
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-red-100 dark:bg-red-950 text-red-600 dark:text-red-400 text-sm font-medium">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" /></svg>
                    Natychmiastowy
                  </span>
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-red-100 dark:bg-red-950 text-red-600 dark:text-red-400 text-sm font-medium">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /></svg>
                    Lokalizacja GPS
                  </span>
                  <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-red-100 dark:bg-red-950 text-red-600 dark:text-red-400 text-sm font-medium">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                    Alert dla okolicy
                  </span>
                </div>
              </div>
            </FadeIn>
          </div>
        </div>
      </section>

      {/* ═══════════ FAMILY TRACKING ═══════════ */}
      <section id="family" className="px-4 sm:px-6 py-20 sm:py-32">
        <div className="max-w-6xl mx-auto">
          <FadeIn>
            <div className="text-center mb-16">
              <span className="text-sm font-semibold text-emerald-500 uppercase tracking-wider">Moduł rodzinny</span>
              <h2 className="text-3xl sm:text-4xl font-bold mt-3 mb-4">Ochrona całej rodziny</h2>
              <p className="text-neutral-600 dark:text-neutral-400 max-w-xl mx-auto">
                Śledź lokalizację dzieci, ustaw bezpieczne strefy i otrzymuj natychmiastowe powiadomienia.
              </p>
            </div>
          </FadeIn>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <FadeIn delay={0}>
              <div className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-8 h-full">
                <div className="w-14 h-14 rounded-2xl bg-emerald-50 dark:bg-emerald-950 flex items-center justify-center text-emerald-500 mb-5">
                  <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" /></svg>
                </div>
                <h3 className="text-xl font-bold mb-3">Grupy rodzinne</h3>
                <p className="text-neutral-600 dark:text-neutral-400 leading-relaxed mb-4">
                  Stwórz grupę i zaproś członków kodem. Rodzice widzą lokalizację dzieci
                  na mapie w czasie rzeczywistym z zielonymi markerami.
                </p>
                <div className="flex items-center gap-2 text-sm text-emerald-600 dark:text-emerald-400">
                  <div className="w-3 h-3 rounded-full bg-emerald-500" />
                  Śledzenie w czasie rzeczywistym
                </div>
              </div>
            </FadeIn>

            <FadeIn delay={100}>
              <div className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-8 h-full">
                <div className="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-950 flex items-center justify-center text-blue-500 mb-5">
                  <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" /></svg>
                </div>
                <h3 className="text-xl font-bold mb-3">Geofencing</h3>
                <p className="text-neutral-600 dark:text-neutral-400 leading-relaxed mb-4">
                  Wyznacz bezpieczne strefy — dom, szkoła, plac zabaw. Gdy dziecko opuści
                  strefę, otrzymasz natychmiastowe powiadomienie.
                </p>
                <div className="flex items-center gap-2 text-sm text-blue-600 dark:text-blue-400">
                  <div className="w-3 h-3 rounded-full bg-blue-500 animate-pulse" />
                  Alert przy wyjściu ze strefy
                </div>
              </div>
            </FadeIn>

            <FadeIn delay={200}>
              <div className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-8 h-full">
                <div className="w-14 h-14 rounded-2xl bg-purple-50 dark:bg-purple-950 flex items-center justify-center text-purple-500 mb-5">
                  <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                </div>
                <h3 className="text-xl font-bold mb-3">Historia lokalizacji</h3>
                <p className="text-neutral-600 dark:text-neutral-400 leading-relaxed mb-4">
                  Przeglądaj trasę dziecka w czasie. Sprawdź gdzie było, kiedy
                  i jak długo. Pełna transparentność dla spokoju rodzica.
                </p>
                <div className="flex items-center gap-2 text-sm text-purple-600 dark:text-purple-400">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" /></svg>
                  Szczegółowa trasa
                </div>
              </div>
            </FadeIn>

            <FadeIn delay={300}>
              <div className="rounded-2xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-8 h-full">
                <div className="w-14 h-14 rounded-2xl bg-rose-50 dark:bg-rose-950 flex items-center justify-center text-rose-500 mb-5">
                  <svg className="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" /></svg>
                </div>
                <h3 className="text-xl font-bold mb-3">Zagrożenia dla dzieci</h3>
                <p className="text-neutral-600 dark:text-neutral-400 leading-relaxed mb-4">
                  5 dedykowanych kategorii: obcy przy dziecku, zagrożenie drogowe, niebezpieczny
                  plac zabaw, zagrożenie wodą, strefa szkolna.
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {['🚸', '🚦', '🛝', '💧', '🏫'].map(e => (
                    <span key={e} className="w-8 h-8 flex items-center justify-center rounded-lg bg-rose-50 dark:bg-rose-950 text-lg">{e}</span>
                  ))}
                </div>
              </div>
            </FadeIn>
          </div>
        </div>
      </section>

      {/* ═══════════ CATEGORIES ═══════════ */}
      <section id="categories" className="px-4 sm:px-6 py-20 sm:py-32 bg-neutral-50 dark:bg-neutral-900/50">
        <div className="max-w-5xl mx-auto">
          <FadeIn>
            <div className="text-center mb-16">
              <span className="text-sm font-semibold text-orange-500 uppercase tracking-wider">Kategorie</span>
              <h2 className="text-3xl sm:text-4xl font-bold mt-3 mb-4">18 typów zagrożeń</h2>
              <p className="text-neutral-600 dark:text-neutral-400 max-w-xl mx-auto">
                Precyzyjne kategorie pozwalają na szybką identyfikację i filtrowanie zagrożeń na mapie.
              </p>
            </div>
          </FadeIn>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {CATEGORIES.map((cat, i) => (
              <FadeIn key={cat.label} delay={i * 50}>
                <div className="flex flex-col items-center gap-2 p-4 rounded-xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 hover:border-neutral-300 dark:hover:border-neutral-700 transition-colors text-center">
                  <div className="w-14 h-14 rounded-xl overflow-hidden">
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={`/icons/categories/${cat.key}.svg`}
                      alt={cat.label}
                      width={56}
                      height={56}
                      className="w-full h-full"
                    />
                  </div>
                  <span className="text-xs font-medium text-neutral-700 dark:text-neutral-300">{cat.label}</span>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════ STATS ═══════════ */}
      <section id="stats" className="px-4 sm:px-6 py-20 sm:py-32">
        <div className="max-w-4xl mx-auto text-center">
          <FadeIn>
            <span className="text-sm font-semibold text-violet-500 uppercase tracking-wider">Platforma</span>
            <h2 className="text-3xl sm:text-4xl font-bold mt-3 mb-16">Liczby mówią same za siebie</h2>
          </FadeIn>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            <FadeIn delay={0}>
              <div className="p-6 rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                <div className="text-3xl sm:text-4xl font-extrabold text-red-500 mb-1">
                  <AnimatedNumber target={18} />
                </div>
                <div className="text-sm text-neutral-500">Kategorii zagrożeń</div>
              </div>
            </FadeIn>
            <FadeIn delay={100}>
              <div className="p-6 rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                <div className="text-3xl sm:text-4xl font-extrabold text-emerald-500 mb-1">24/7</div>
                <div className="text-sm text-neutral-500">Monitoring</div>
              </div>
            </FadeIn>
            <FadeIn delay={200}>
              <div className="p-6 rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                <div className="text-3xl sm:text-4xl font-extrabold text-blue-500 mb-1">
                  &lt;<AnimatedNumber target={1} />s
                </div>
                <div className="text-sm text-neutral-500">Czas powiadomienia</div>
              </div>
            </FadeIn>
            <FadeIn delay={300}>
              <div className="p-6 rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800">
                <div className="text-3xl sm:text-4xl font-extrabold text-violet-500 mb-1">
                  <AnimatedNumber target={2} />
                </div>
                <div className="text-sm text-neutral-500">Platformy (Android + Web)</div>
              </div>
            </FadeIn>
          </div>
        </div>
      </section>

      {/* ═══════════ HOW IT WORKS ═══════════ */}
      <section className="px-4 sm:px-6 py-20 sm:py-32 bg-neutral-50 dark:bg-neutral-900/50">
        <div className="max-w-4xl mx-auto">
          <FadeIn>
            <div className="text-center mb-16">
              <span className="text-sm font-semibold text-cyan-500 uppercase tracking-wider">Jak to działa</span>
              <h2 className="text-3xl sm:text-4xl font-bold mt-3">Trzy proste kroki</h2>
            </div>
          </FadeIn>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              {
                step: '01',
                title: 'Zauważ zagrożenie',
                desc: 'Widzisz niebezpieczeństwo? Kliknij na mapie lub użyj przycisku „Zgłoś".',
                icon: <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>,
              },
              {
                step: '02',
                title: 'Opisz i zgłoś',
                desc: 'Wybierz kategorię, dodaj opis i opcjonalnie zdjęcie. Zajmie to kilka sekund.',
                icon: <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" /></svg>,
              },
              {
                step: '03',
                title: 'Społeczność reaguje',
                desc: 'Inni użytkownicy widzą zagrożenie, potwierdzają je i są bezpieczni.',
                icon: <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>,
              },
            ].map((item, i) => (
              <FadeIn key={item.step} delay={i * 150}>
                <div className="text-center">
                  <div className="w-16 h-16 rounded-2xl bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 flex items-center justify-center text-red-500 mx-auto mb-4 shadow-sm">
                    {item.icon}
                  </div>
                  <div className="text-xs font-bold text-red-500 mb-2">{item.step}</div>
                  <h3 className="text-lg font-bold mb-2">{item.title}</h3>
                  <p className="text-sm text-neutral-600 dark:text-neutral-400">{item.desc}</p>
                </div>
              </FadeIn>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════ FINAL CTA ═══════════ */}
      <section className="px-4 sm:px-6 py-20 sm:py-32">
        <div className="max-w-3xl mx-auto text-center">
          <FadeIn>
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-r from-red-500/10 via-orange-500/10 to-red-500/10 rounded-3xl blur-2xl" />
              <div className="relative rounded-3xl border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 p-10 sm:p-16">
                <div className="w-16 h-16 rounded-2xl bg-red-500 flex items-center justify-center mx-auto mb-6">
                  <span className="text-white font-bold text-xl">b:S</span>
                </div>
                <h2 className="text-3xl sm:text-4xl font-bold mb-4">Zacznij chronić swoją okolicę</h2>
                <p className="text-neutral-600 dark:text-neutral-400 mb-8 max-w-lg mx-auto">
                  Dołącz do społeczności be:Safe. Za darmo, bez reklam. Twoje bezpieczeństwo
                  i bezpieczeństwo Twojej rodziny jest najważniejsze.
                </p>
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                  <a
                    href="https://alert.u235.pl/api/v1/download"
                    className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-red-500 text-white font-semibold hover:bg-red-600 transition-all shadow-xl shadow-red-500/25 hover:shadow-red-500/40"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" /></svg>
                    Pobierz APK na Android
                  </a>
                  <a
                    href="/"
                    className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl bg-neutral-100 dark:bg-neutral-800 text-neutral-900 dark:text-white font-semibold hover:bg-neutral-200 dark:hover:bg-neutral-700 transition-colors"
                  >
                    Otwórz wersję webową
                  </a>
                </div>
                <p className="text-xs text-neutral-400 mt-6">
                  Darmowe. Bez reklam. Open-source.
                </p>
              </div>
            </div>
          </FadeIn>
        </div>
      </section>

      {/* ═══════════ FOOTER ═══════════ */}
      <footer className="border-t border-neutral-200 dark:border-neutral-800 px-4 sm:px-6 py-10">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-red-500 flex items-center justify-center">
              <span className="text-white font-bold text-xs">b:S</span>
            </div>
            <span className="font-semibold text-sm">be:Safe</span>
            <span className="text-neutral-400 text-sm">— Community Safety Alert System</span>
          </div>
          <div className="flex items-center gap-6 text-sm text-neutral-500">
            <a href="/" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Aplikacja webowa</a>
            <a href="https://alert.u235.pl/api/v1/download" className="hover:text-neutral-900 dark:hover:text-white transition-colors">Pobierz APK</a>
            <span>&copy; {new Date().getFullYear()} u235.pl</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
