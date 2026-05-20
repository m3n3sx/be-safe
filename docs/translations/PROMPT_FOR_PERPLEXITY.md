# Prompt dla Perplexity / ChatGPT — tłumaczenia be:Safe (F23)

## Kontekst

**be:Safe** to polska aplikacja bezpieczeństwa społeczności (Flutter + Node.js, https://besafe.org.pl). Użytkownicy zgłaszają zagrożenia w okolicy (kradzież, pożar, agresja, wypadek, pogoda), tworzą rodzinne grupy bezpieczeństwa, korzystają z SOS, śledzenia rodziny i bezpiecznych tras. Aplikacja ma 3 tryby (KIDS 7-12 lat, SENIOR 60+, NORMAL 13-59).

Aplikacja jest obecnie w **języku polskim** i ma podstawowe wsparcie EN (87 kluczy). Chcemy dodać:
- pełne **angielskie** tłumaczenia (cel: użytkownicy międzynarodowi, turyści w PL)
- pełne **ukraińskie** tłumaczenia (cel: uchodźcy wojenni z Ukrainy mieszkający w PL)

## Twoje zadanie

Przetłumacz załączony słownik stringów polskich na **English (en)** i **Ukrainian (uk)**.

## Zasady tłumaczenia

1. **Ton i rejestr**: 
   - PL używa formy "Ty/wy" (nieformalne, ciepłe). Zachowaj ten styl w EN i UA.
   - EN: prosty, friendly, bez biurokratycznego żargonu. Brytyjski lub neutralny.
   - UA: nieformalne "ти", ale szanujące (typowy ton ukraińskich apek bezpieczeństwa).

2. **Dziedzina**: aplikacja safety/emergency. Terminy techniczne powinny brzmieć **naturalnie** dla użytkownika końcowego, nie dosłownie:
   - "Zgłoś zagrożenie" → "Report a hazard" (NIE "Report a threat" — brzmi militarnie)
   - "Bezpieczna trasa" → "Safe route"
   - "Bezpieczna strefa" / "geofence" → "Safe zone"
   - "Eskorta" / "Follow Me" → "Escort" / "Follow me" (zachowaj angielską nazwę funkcji)
   - "Sygnał" (ping rodzinny) → "Check-in request" / "Ping"
   - "Zameldowanie" (senior) → "Check-in"
   - "KPP" (Kwalifikowana Pierwsza Pomoc) → "Certified first responder" (EN) / "Сертифікований рятувальник" (UA)

3. **Polskie konkretne nazwy**: 
   - **Numery alarmowe PL (112, 997, 998, 999, 992)** — zostaw bez zmian, dodaj objaśnienie w nawiasie po angielsku/ukraińsku w razie potrzeby.
   - **mObywatel, CERT.pl, Bezpiecznedane.gov.pl, Telefon Zaufania** — zostaw oryginalne nazwy.
   - **PESEL** — zostaw bez zmian (specyfika PL).
   - "Straż Pożarna", "Policja", "Pogotowie" → przetłumacz normalnie (Fire department, Police, Ambulance).

4. **Emoji i ikony**: zachowaj WSZYSTKIE emoji (🆘, 🚨, ✓, ⚠️, 🚒, 🏥, 📍 itd.) w identycznym miejscu.

5. **Skróty i etykiety przycisków**:
   - PL "POMOC" → EN "HELP", UA "ДОПОМОГА"
   - PL "MAPA" → EN "MAP", UA "КАРТА"
   - PL "RODZINA" → EN "FAMILY", UA "СІМ'Я"
   - PL "JESTEM OK" → EN "I'M OK", UA "Я В ПОРЯДКУ"
   - PL "SOS" → "SOS" (wszędzie tak samo)
   - PL "ZAMELDUJ SIĘ" (senior daily check-in) → EN "CHECK IN", UA "ВІДМІТИТИСЯ"

6. **Frazy specyficzne dla seniora**:
   - "Cześć, {imię}!" → EN "Hi, {name}!", UA "Привіт, {name}!"
   - "DZIEŃ DOBRY" (Senior topbar) → EN "GOOD DAY", UA "ДОБРОГО ДНЯ"
   - "JESTEŚ BEZPIECZNA" (KIDS hero chip) → EN "YOU ARE SAFE", UA "ТИ В БЕЗПЕЦІ"

7. **Niezmienne**:
   - "be:Safe" (nazwa apki) — NIE tłumaczyć
   - placeholdery `${name}`, `${count}`, `$_alertsNearby`, `${widget.userName}` — zachowaj dokładnie
   - znaki `\n`, `•`, `—` — zachowaj
   - klucze JSON (po lewej stronie) — NIE zmieniaj

8. **Długość**: tłumaczenia powinny być zbliżone do PL pod względem długości (UI ma layoutowe ograniczenia). Jeśli EN/UA jest znacząco dłuższe, postaraj się skrócić bez utraty sensu.

## Format wyjściowy

Dla każdego pliku JSON zwróć **kompletny obiekt** z kluczami `en` i `uk` (Ukrainian = `uk` w ISO 639-1, **NIE** `ua`):

```json
{
  "en": {
    "app_name": "be:Safe",
    "map": "Map",
    "family": "Family",
    ...
  },
  "uk": {
    "app_name": "be:Safe",
    "map": "Карта",
    "family": "Сім'я",
    ...
  }
}
```

## Pliki do tłumaczenia (kolejność)

1. **`i18n_core_pl.json`** — istniejący słownik (87 kluczy, EN już jest, popraw / uzupełnij + dodaj UA)
2. **`i18n_extended_pl.json`** — ~150 nowych kluczy z nowych funkcji (F33 tryby, F11 AED, F21 senior check-in, F26 mental health, F27 poradnik, F25 pet mode, F28 cyber-safety, F03 escort, F01 fake call, F04 crash detection, F07 shake-to-SOS, F14 family chat, F17 anonimowe, F19 family planner)
3. **`i18n_buttons_actions_pl.json`** — krótkie etykiety, akcje, statusy (najczęściej używane)

## Ostateczny format do mojego deweloperskiego użycia

Po przetłumaczeniu zwróć **JEDEN plik master** w formacie:

```json
{
  "pl": { ... wszystkie klucze po polsku ... },
  "en": { ... wszystkie klucze po angielsku ... },
  "uk": { ... wszystkie klucze po ukraińsku ... }
}
```

Ten plik zaimportuję do `lib/services/i18n.dart`.

## Co WAŻNE

- Bezpieczeństwo dziecka, pomoc seniora, alert kryzysowy — to **kontekst krytyczny**. Lepsze błędne tłumaczenie wstrzymane niż dosłowne ale niezrozumiałe.
- Jeśli masz wątpliwość w UA (np. region terminologii) — wybierz **standardowy ukraiński literacki** używany w mediach.
- Zachowaj wszystkie placeholdery, znaki specjalne, długość zbliżoną.

## Pominięte z zakresu

- F13 mObywatel KWIE — funkcja wymaga integracji rządowej, nie tłumaczymy interfejsu (na razie)
- Logi developerskie (`debugPrint`, `[FCM] Error...`) — to nie UI

---

**Po zakończeniu**: wgraj mi gotowy plik `i18n_master.json`, a ja zintegruję go z `lib/services/i18n.dart` i opublikuję v60 z 3 językami.
