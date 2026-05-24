'use client';

import React from 'react';

interface Tool {
  title: string;
  desc: string;
  url: string;
  icon: string;
  bg: string;
}

const tools: Tool[] = [
  { title: 'mObywatel — Bezpieczny PESEL', desc: 'Zastrzeż swój PESEL, aby nikt nie wziął na Ciebie kredytu.', url: 'https://www.gov.pl/web/mobywatel/zastrzezenia', icon: '🔒', bg: 'bg-[#1A2027] text-white' },
  { title: 'Bezpiecznedane.gov.pl', desc: 'Sprawdź, czy Twoje dane wyciekły i co zrobić, gdy zostały wykradzione.', url: 'https://bezpiecznedane.gov.pl', icon: '🛡️', bg: 'bg-[#9DF4CB] text-[#1A2027]' },
  { title: 'Have I Been Pwned', desc: 'Globalna baza wycieków danych — sprawdź swój e-mail.', url: 'https://haveibeenpwned.com', icon: '📧', bg: 'bg-[#9EEBEC] text-[#1A2027]' },
  { title: 'CERT.pl', desc: 'Zgłoś phishing, oszustwo SMS lub fałszywą stronę.', url: 'https://incydent.cert.pl', icon: '⚠️', bg: 'bg-[#FF7A7A] text-white' },
  { title: 'Numer 8080 — phishing SMS', desc: 'Prześlij dalej podejrzaną wiadomość SMS na numer 8080 (CERT Orange).', url: 'sms:8080', icon: '💬', bg: 'bg-amber-400 text-[#1A2027]' },
];

const tips = [
  'Używaj różnych haseł do każdego serwisu. Menedżer haseł (Bitwarden, 1Password) pomoże.',
  'Włącz weryfikację dwuetapową (2FA) wszędzie, gdzie się da — szczególnie w banku i poczcie.',
  'NIE klikaj linków z SMS-ów typu „doplata 1zł" / „kurier" / „zwrot podatku". To prawie zawsze phishing.',
  'Sprawdzaj adres strony przed wpisaniem hasła. Banki nigdy nie proszą o pełne hasło/PIN.',
  'Zastrzeż PESEL przez mObywatela jeśli zgubiłeś dowód lub padłeś ofiarą wycieku.',
  'Nie udostępniaj w mediach społecznościowych zdjęć dokumentów (dowód, prawo jazdy).',
];

export default function CyberSafetyPage() {
  return (
    <div className="min-h-screen bg-neutral-50 dark:bg-neutral-950 px-4 py-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-light text-neutral-900 dark:text-white mb-2">🛡️ Cyberbezpieczeństwo</h1>
      <p className="text-sm text-neutral-500 mb-6">Praktyczne narzędzia i porady</p>

      <h2 className="text-sm font-semibold uppercase tracking-wide text-neutral-500 mb-3">Narzędzia</h2>
      <div className="space-y-2 mb-8">
        {tools.map(t => (
          <a
            key={t.title}
            href={t.url}
            target={t.url.startsWith('http') ? '_blank' : undefined}
            rel="noreferrer"
            className={`block ${t.bg} rounded-2xl p-4 hover:opacity-95 transition-all`}
          >
            <div className="flex items-center gap-4">
              <div className="text-2xl">{t.icon}</div>
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{t.title}</div>
                <div className="text-xs opacity-90 mt-0.5">{t.desc}</div>
              </div>
              <svg className="w-5 h-5 opacity-70" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
              </svg>
            </div>
          </a>
        ))}
      </div>

      <h2 className="text-sm font-semibold uppercase tracking-wide text-neutral-500 mb-3">Najważniejsze zasady</h2>
      <div className="bg-white dark:bg-neutral-900 rounded-2xl divide-y divide-neutral-100 dark:divide-neutral-800">
        {tips.map((tip, i) => (
          <div key={i} className="flex items-start gap-3 p-4">
            <div className="w-7 h-7 rounded-full bg-[#9DF4CB] text-[#1A2027] font-bold text-xs flex items-center justify-center flex-shrink-0">
              {i + 1}
            </div>
            <p className="text-sm text-neutral-700 dark:text-neutral-300 leading-relaxed">{tip}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
