# 04 — Assets Checklist (co wyciągnąć z Stitch do repo)

Gdy masz gotowy design w Stitchu, zapisz następujące rzeczy do `/home/ooxo/alert/design/stitch-export/`:

## Screenshoty PNG (priorytet)

Każdy ekran w 3 rozdzielczościach:
- **Phone** (1080×2400) — domyślny target Androida
- **Tablet** (1600×2560) — dla testów responsywnych
- **Dark mode** — ten sam ekran w trybie ciemnym

Nazwy plików:
```
01_map_phone_light.png
01_map_phone_dark.png
01_map_tablet_light.png
02_onboarding_1_phone.png
02_onboarding_2_phone.png
...
```

**Jak wyciągać:** w Stitch po najechaniu na screen są guziki Download PNG.
Albo przez MCP (patrz `05_MCP_WORKFLOW.md`): `get_screen_image`.

## HTML/CSS każdego screena (opcjonalnie)

Przydatne gdy chcesz użyć designu jako referencji w AI coding agencie.
`get_screen_code` przez MCP zwraca HTML/CSS.

Zapisuj do:
```
design/stitch-export/html/01_map.html
design/stitch-export/html/01_map.css
design/stitch-export/html/02_onboarding_1.html
...
```

## Palette / theme tokens (jeśli wyeksportujesz do Figma)

Jeśli przeklikniesz Stitch → **Export to Figma**, weź stamtąd Design Tokens.
Zapisz jako:
```
design/stitch-export/tokens.json
```

Potem możesz zmapować na Flutter `ColorScheme.fromSeed(...)`.

## Lista screenów z ich Stitch ID

Po utworzeniu projektu Stitch wypisze listę screenów z ID. Zapisz jako:
```
design/stitch-export/SCREENS.md
```

Format:
```markdown
| Screen | Stitch ID | Status |
|---|---|---|
| Map | abc123 | ✅ Done |
| Onboarding 1 | def456 | ✅ Done |
| Login | ghi789 | 🚧 Iter 2 |
```

Po co: żebyś mógł za pomocą `get_screen_code abc123` wyciągnąć konkretny ekran.

## Video / GIF animacji (opcjonalne)

Stitch umożliwia generowanie **prototype animacji** (przejścia między ekranami).
Jeśli wygenerujesz — eksportuj jako MP4, wrzuć do:
```
design/stitch-export/prototypes/flow_login_to_map.mp4
```

## Finalne: branding assets

Stitch może wygenerować logo/ikony. Dla be:Safe potrzebujesz:

- **App icon** — 1024×1024 PNG (dla Google Play)
- **Adaptive icon** — foreground 432×432 + background 432×432 (Android)
- **Feature graphic** — 1024×500 (Google Play listing)
- **Splash screen** — 1242×2688 (iOS + Android)

Zapisz do:
```
design/stitch-export/branding/
  icon_1024.png
  icon_adaptive_foreground.png
  icon_adaptive_background.png
  feature_graphic_1024x500.png
  splash_1242x2688.png
```

## Co z tymi assetami robić dalej

1. **Screenshoty** → upload na Google Play Console w zakładce "Sklep"
2. **Adaptive icon** → podmień `mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`
   (użyj Android Studio Image Asset generator)
3. **Feature graphic** → Google Play listing "Grafika funkcji"
4. **HTML/CSS** → referencja dla następnej sesji AI refactorującej UI Flutter
5. **Tokens** → można wygenerować `mobile/lib/theme/design_tokens.dart`

---

**Quick commands** po pobraniu:

```bash
# Porządkuj
mkdir -p design/stitch-export/{screens,html,branding,prototypes}

# Git: commituj tylko finalne PNG (.gitignore dla robo-export)
git add design/stitch-export/screens/*_final.png design/stitch-export/branding/
```
