# be:Safe — pakiet do Google Stitch

Kompletny zestaw materiałów do wygenerowania designu aplikacji **be:Safe**
w [Google Stitch](https://stitch.withgoogle.com).

## Jak używać

1. **Najpierw przeczytaj `DESIGN_BRIEF.md`** — design system i kontekst produktu.
2. **Otwórz Stitch** (`stitch.withgoogle.com`) i zacznij nowy projekt.
3. **Wklej `01_MASTER_PROMPT.md`** jako pierwszy prompt — Stitch wygeneruje
   bazę (map + bottom nav + SOS).
4. **Iteruj screen-by-screen** używając promptów z `02_SCREEN_PROMPTS.md`.
   **Zawsze jeden prompt = jedna zmiana.** Stitch resetuje layout gdy dostanie
   zbyt wiele zmian naraz.
5. Jeśli coś poszło nie tak — użyj `03_RECOVERY_PROMPTS.md` (rollback patterns).
6. Gdy masz gotowe screeny — sprawdź `04_ASSETS_CHECKLIST.md` żeby wiedzieć
   co potem wyciągnąć z Stitcha do repo Flutter.

## Pliki w pakiecie

| Plik | Co zawiera |
|---|---|
| `DESIGN_BRIEF.md` | Design system: kolory, typografia, layout, komponenty, vibe |
| `01_MASTER_PROMPT.md` | Pierwszy prompt — baza aplikacji (main + nav + SOS) |
| `02_SCREEN_PROMPTS.md` | 18 promptów, jeden per ekran, w kolejności iteracji |
| `03_RECOVERY_PROMPTS.md` | Prompty naprawcze gdy Stitch zepsuł layout |
| `04_ASSETS_CHECKLIST.md` | Co eksportować z Stitch do repo Flutter |
| `05_MCP_WORKFLOW.md` | Jak użyć Stitch MCP do wyciągania kodu/obrazów |

## Szybka ściągawka

**Prompt formula:**
```
[Screen name] + [purpose] + [key elements] + [vibe/colors]
```

**Vibe dla be:Safe:**
> Trustworthy, modern, community-focused, safety-first.
> Red-accented (alert red) with calm neutrals. Material 3, high readability.
> Family-friendly but not childish. Polish language.

**Czego NIE robić:**
- Nie dawaj wielu zmian w jednym prompcie → Stitch zresetuje layout
- Nie zmieniaj theme w środku projektu → zacznij od nowa
- Nie używaj prompów > 5000 znaków → ucina komponenty
- Nie wymieniaj > 3 screenów naraz

**Co działa najlepiej:**
- Rozpocznij od `01_MASTER_PROMPT.md`
- Po każdym screen — zrób screenshot (Stitch czasem traci zmiany)
- Używaj dokładnych nazw: "primary button in header", "red SOS button in bottom nav"
- Dla polskich tekstów dodaj `Switch all text to Polish.` na końcu promptu
