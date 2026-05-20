# be:Safe — Pakiet tłumaczeń (F23)

## Co tu jest

Paczka gotowa do wysyłki **Perplexity / ChatGPT / Claude** do tłumaczenia interfejsu be:Safe z **polskiego** na **angielski (en)** i **ukraiński (uk)**.

## Pliki

| Plik | Zawartość | Liczba kluczy |
|---|---|---|
| `PROMPT_FOR_PERPLEXITY.md` | Instrukcja krok po kroku dla modelu AI (jak tłumaczyć, jaki ton, format wyjścia) | — |
| `i18n_core_pl.json` | Istniejący słownik z `lib/services/i18n.dart`. PL+EN gotowe, brakuje UA. | 87 |
| `i18n_extended_pl.json` | Nowe klucze z funkcji v50-v59 (F33 tryby, F11 AED, F21 senior, F26 mental health, F27 poradnik, F25 pets, F28 cyber, F03 escort, F01 fake call, F04 crash, F07 shake, F14 chat, F17 anon, F19 planner) | ~150 |
| `i18n_buttons_actions_pl.json` | Akcje, dialogi, statusy, kategorie alertów | ~80 |

**Razem: ~320 kluczy.**

> ℹ️ Aplikacja ma jeszcze ~270 hardcodowanych polskich stringów w nowych ekranach (poradnik, RKO, cyber-tipy). Te są w plikach `.dart` jako literały. Refaktor migracji ich do `i18n.dart` to osobne zadanie (~2 dni) — zaplanowane na v61.

## Workflow

1. **Wyślij Perplexity prompt** z `PROMPT_FOR_PERPLEXITY.md` + załącz 3 pliki JSON
2. Perplexity zwróci 3 pliki z uzupełnionymi `en` i `uk` (lub jeden master)
3. Dewelopuje (skrypt Pythona) złożymy je w `lib/services/i18n.dart` jako 3-poziomową mapę `{'pl': {...}, 'en': {...}, 'uk': {...}}`
4. Dodanie wyboru języka w **Ustawienia → Język** (już istnieje, doda się 'uk' do `availableLanguages`)
5. Build v60 + deploy

## Co po stronie aplikacji trzeba zmienić po otrzymaniu tłumaczeń

```dart
// lib/services/i18n.dart
static const Map<String, Map<String, String>> _strings = {
  'pl': { ... },
  'en': { ... },  // ROZSZERZONY
  'uk': { ... },  // NOWY
};

static List<String> get availableLanguages => ['pl', 'en', 'uk'];
static String langName(String code) => switch (code) {
  'pl' => 'Polski',
  'en' => 'English',
  'uk' => 'Українська',
  _ => code
};
```

Plus integracja kluczy w ekranach: zamienić `'Cześć, Ania!'` na `S.get('kids_greeting').replaceAll('{name}', name)`. To stopniowo, ekran po ekranie.

## Pominięte

- **F13 mObywatel KWIE** — integracja rządowa, nie ma sensu tłumaczyć interfejsu zanim nie zaimplementujemy
- **Logi developerskie** (`debugPrint`, `[FCM]`, `[CRASH]`) — nie są UI
- **Komunikaty exceptions/errors w try/catch** typu `'Błąd: $e'` — wewnętrzny debug

## Status

- ✅ Pliki gotowe
- ⏳ Wysyłka do Perplexity (zewnętrzne, użytkownik)
- ⏳ Integracja zwrotnych tłumaczeń w `i18n.dart` (deweloper, ~30 min)
- ⏳ Refaktor hardcoded stringów w ekranach na `S.get()` (deweloper, ~2 dni, osobny v61)
