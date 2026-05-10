# 08 — Figma Export Workflow

> Skleić design Stitcha (be:Safe Community Modern) w Figma, żeby projektant
> mógł dopracować, a my mieli cenne tokens + komponenty do importu.

## Plik do importu

**`design/besafe-figma-export.zip`** (12 MB) zawiera:

- **36 rekomendowanych screenów** (z `MASTER_STYLE.md` sekcja 4) — każdy w swoim folderze z `index.html` (Stitch render) + `screen.png` (referencja wizualna).
- **`MASTER_STYLE.md`** — pełny design system dokument.

Screeny w ZIPie (w kolejności scenariusza):

| Grupa | Screeny |
|---|---|
| **Mapa** | `mapa_m3_expressive_2` (base), `mapa_m3_expressive_1` (glass variant), `mapa_tablet` |
| **Onboarding** | `onboarding_m3_expressive`, `onboarding_1_powitanie` .. `onboarding_5_start` |
| **Alert** | `zg_o_zagro_enie_m3_expressive` (create), `szczeg_y_alertu_m3_expressive` (detail) |
| **Profil** | `profil_m3_expressive_1` (primary), `_2`, `_edycja`, `_adowanie`, `_brak_aktywno_ci` |
| **Moje zgłoszenia** | `moje_zg_oszenia_m3_expressive`, `_be_safe` |
| **Alerty list** | `alerty_m3_expressive_2`, `_1` |
| **SOS** | `sos_m3_expressive_2`, `_1` |
| **Rodzina** | `rodzina_m3_expressive`, `rodzina_brak_grup`, `grupa_rodzinna_mapa`, `_cz_onkowie`, `historia_lokalizacji` |
| **Odznaki/News/Ranking** | `odznaki_m3_expressive`, `aktualno_ci_m3_expressive`, `ranking_m3_expressive` |
| **Referral/Emergency** | `zapro_znajomych`, `numery_alarmowe_m3_expressive` |
| **Settings/Legal** | `ustawienia_m3_expressive`, `regulamin_m3_expressive`, `polityka_prywatno_ci` |
| **Stats** | `statystyki_m3_expressive` |

## Import do Figma — 2 ścieżki

### ★ Ścieżka A: html.to.design plugin (rekomendowana, działa dla wszystkich)

1. Otwórz **Figma** (web lub desktop) → nowy plik.
2. Menu ** → Plugins → Manage plugins → "html.to.design"** → Install.
3. Uruchom plugin: prawy panel Figmy → **html.to.design**.
4. Zakładka **"File"** → wrzuć `design/besafe-figma-export.zip`.
5. W opcjach pluginu:
   - **Breakpoint:** Mobile (390x844) dla większości, Tablet (1024x1366) dla `mapa_tablet`.
   - **Layout mode:** Auto-layout ON (przydatne do edycji).
   - **Images:** Include (zaimportuje też screen.png jako referencję).
6. Plugin renderuje każdy HTML jako Figma frame w aktywnej stronie. Każdy screen trafia na osobną stronę Figmy (albo wszystkie w jednej z gapem 100px).
7. Zajmie ~2–5 min (12 MB, 36 screenów).

Po imporcie:
- W Figma **Layers** masz każdy screen jako frame z pełnym drzewem komponentów (divy → Frames, spans → Text nodes).
- Dodaj **Variables** dla kolorów z `MASTER_STYLE.md` sekcja 2.1 (Figma → Variables panel → create from JSON).
- Skonwertuj powtarzalne elementy (bottom nav, stat tile, alert card) na **Components** (Cmd/Ctrl + Alt + K).
- Zapisz jako **Library** i share z projektantem/zespołem.

### Ścieżka B: Stitch natywny "Paste to Figma" (tylko Rapid projects)

1. Otwórz https://stitch.withgoogle.com
2. Otwórz projekt **"be:Safe Community Safety App"** (widoczny jako ostatnio edytowany — mieliśmy tam wrzucony `MASTER_STYLE.md` jako design asset).
3. Wybierz pojedynczy screen → prawy górny róg **More → Export → Copy to Figma** (jeśli dostępne; dostępne tylko dla projektów utworzonych w Rapid mode).
4. Przejdź do Figmy → Cmd/Ctrl + V.
5. Powtórz dla każdego screena.

**Uwaga:** ta opcja **nie działa** dla projektów non-Rapid (twój jest non-Rapid — w MCP listach widać `deviceType: MOBILE` bez `rapidMode`). Dlatego ścieżka A jest bardziej niezawodna.

## Co robić gdy design jest w Figmie

### 1. Figma Variables (tokens)
Wklej z `MASTER_STYLE.md` sekcja 2.1 wartości jako Figma Variables:
- **Color/Primary**: `#BA002C`
- **Color/Secondary**: `#006E2A`
- **Color/Surface**: `#FFF8F7`
- ... itd.

W Figma: `Local Variables` → `+` → **Color** → wklej hex.

### 2. Components (reusable)
Wykonaj te komponenty jako Figma Components (Cmd+Alt+K na wzorcowym elemencie):
- `FloatingBottomNav` (variant: tab=Map/Alerty/SOS/Family/Profile, state=active/inactive)
- `StatTile` (variant: color=primary/neutral, value=string, label=string)
- `AlertCard` (variant: status=new/in-progress/resolved/expired, category=8 accents)
- `CategoryChip` (variant: selected boolean, 17 category values)
- `PrimaryPillButton`, `SecondaryOutlinedButton`, `HeroSOSButton`
- `MapPin`, `ChildPin`, `ClusterPin` (osobne komponenty)

### 3. Handoff do Flutter
Figma → Inspect → kopiuj CSS → zamapuj na Flutter widgety. Zachęcam do użycia:
- **`flutter_figma`** package (auto-sync tokens)
- **`figma-export`** CLI (Figma → `design_tokens.dart`)
- Albo manual: `mobile/lib/theme/design_tokens.dart` z paletą z sekcji 2.1 `MASTER_STYLE.md`.

## Przydatne linki

- [html.to.design plugin](https://www.figma.com/community/plugin/1159123024924461424/html-to-design)
- [Stitch MCP tools docs](https://github.com/davideast/stitch-mcp)
- [Material 3 Expressive spec](https://m3.material.io/styles)
- [Figma Variables dla color tokens](https://help.figma.com/hc/en-us/articles/15145852043927)

## Potem

Jeśli zdecydujesz się wrócić do **Opcji B (implementacja Flutter)** po przejściu przez Figma:
- Projektant odświeża / redesignuje w Figma
- Exportuje design tokens jako JSON (`Tokens Studio for Figma` plugin)
- Ja konwertuję JSON → `mobile/lib/theme/design_tokens.dart`
- PR-y per screen bazujące na zaktualizowanym Figma spec
