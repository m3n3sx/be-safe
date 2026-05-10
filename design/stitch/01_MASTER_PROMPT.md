# 01 — Master Prompt (pierwszy prompt do Stitcha)

> **Jak użyć:** otwórz [stitch.withgoogle.com](https://stitch.withgoogle.com),
> kliknij **New Project**, ustaw platformę na **Mobile (Android)**,
> i wklej poniższy prompt jako pierwszy input.
>
> Prompt jest przygotowany w formie opisu naturalnego języka (Vincent Nallatamby
> z Google zaleca "plain language, simple prompt to start"). Ok. 1200 znaków —
> w bezpiecznej strefie (< 5000 max).

---

## Prompt (skopiuj wszystko poniżej, tylko tekst):

```
A trustworthy community safety app for Poland called "be:Safe". It helps neighbors warn each other about local threats and lets parents track their children on a shared family map.

Main screen: a full-screen Google-style map centered on the user's location. Red warning pins mark reported threats (fights, theft, fire, accidents, bad lighting). Pins with count badges cluster at lower zoom. Green pins show the user's children when the family mode is active. A rounded search bar floats at the top with filter and my-location icons. A large red "Zgłoś" (Report) button sits just above the bottom navigation.

Bottom navigation has five items: Mapa (Map), Alerty (Alerts with red dot badge for new items), a big round red SOS button in the center, Rodzina (Family), Profil (Profile). The SOS button is visually dominant, deep red circle with white bold "SOS" text.

Design vibe: modern Material 3, clean, safety-focused but not scary. Primary alert red (#FF1744), calm grey neutrals, safe green for family. Rounded 16dp cards, 28dp pill-shaped primary buttons, Inter/Google Sans font. Light mode default with clean white surfaces, proper dark mode too.

All UI text in Polish. Add a subtle safety shield icon in the app branding.
```

---

## Co oczekiwać

Stitch wygeneruje **5–8 screenów** startowych (Home + wariacje). Najważniejszy
to **Map screen** — weryfikuj go najpierw.

**Checklist po pierwszej generacji (przed iteracją):**
- [ ] Mapa widoczna na pełnym ekranie
- [ ] Bottom nav ma 5 items w tym SOS w środku
- [ ] SOS jest czerwony, wyróżniony wizualnie
- [ ] Przycisk "Zgłoś" nad bottom nav, kolor czerwony
- [ ] Ikony warning pins widoczne na mapie
- [ ] Search bar u góry z search icon i filter icon
- [ ] Teksty PO POLSKU (Mapa, Alerty, Rodzina, Profil, Zgłoś)
- [ ] Brak elementów corpo/sterilnych

**Jeśli któryś z powyższych nie jest OK** — przejdź do `03_RECOVERY_PROMPTS.md`,
sekcja "Fix bottom nav" / "Fix map screen".

## Co robić zaraz potem

Nie zaczynaj zmieniać głównego screena od razu. Idź do `02_SCREEN_PROMPTS.md` i
generuj kolejne screeny **jeden po drugim**. Gdy masz komplet — wróć do Map
i dopracuj szczegóły.
