# 03 — Recovery Prompts (naprawa gdy Stitch zepsuł layout)

> Wg community feedback: Stitch **często traci poprzedni layout** gdy dostanie
> prompt dotyczący wielu rzeczy naraz. Poniżej wzorce do przywracania/naprawy.

---

## Zasada ogólna

Jeśli zmieniałeś coś i wszystko poszło nie tak:
1. **Nie panikuj** — Stitch trzyma historię. Użyj "undo" w UI.
2. Jeśli undo nie wystarcza — **rollback do ostatniego działającego screenshoot**
   opisując go zdaniem.
3. Niech **jedna linia = jedna zmiana**. Bez "and also".

---

## 3.1 Fix bottom navigation

```
On the home screen, the bottom navigation should have exactly 5 items in this order: Mapa (map icon), Alerty (notification icon with optional red dot), a large red circular SOS button in the center, Rodzina (family icon), Profil (person icon). Make the SOS button visually larger than the other four items.
```

---

## 3.2 Fix SOS button style

```
On the bottom navigation, replace the center item with a circular button 56dp wide, solid red (#FF1744), containing bold white "SOS" text. No icon, just the text. The button should sit slightly above the other nav items for emphasis.
```

---

## 3.3 Fix map rendering

```
On the home screen, restore the full-screen map as the background. The map should occupy 100% of the screen area behind all overlays. The bottom navigation and the floating "Zgłoś" button should sit above the map with no grey background behind them.
```

---

## 3.4 Fix Polish language

```
Switch all UI text to Polish. Button labels, navigation items, placeholder text, section headings. Keep emoji and icons as they are. Use "Zgłoś", "Mapa", "Alerty", "Rodzina", "Profil", "Zaloguj się", "Potwierdzam", "Nieaktualne", "Komentarze".
```

---

## 3.5 Fix color theme

```
Reset the primary color of the entire app to alert red (#FF1744). Use this for the Zgłoś button, SOS button, primary CTAs, and the app accent. Secondary actions (family, check-in) use green (#00C853). Keep surfaces white in light mode and near-black (#121212) in dark mode.
```

---

## 3.6 Fix typography

```
Use a clean modern sans-serif font for all text — Inter or Google Sans Text. Headings should be bold (700), body regular (400), buttons semi-bold (600). No decorative or script fonts anywhere in the app.
```

---

## 3.7 Fix rounded corners

```
All cards should have 16dp rounded corners. Primary action buttons (Zgłoś, Zaloguj, Opublikuj) should be pill-shaped (fully rounded). Input fields should have 12dp rounded corners. No sharp 90-degree corners anywhere except thin dividers.
```

---

## 3.8 Fix spacing (za ciasno lub za luźno)

```
Use Material 3 spacing: 16dp horizontal margins on mobile. 16dp vertical spacing between distinct sections, 8dp between related items. Cards have internal padding of 16dp. List items have 56dp minimum height for easy tapping.
```

---

## 3.9 Fix alert pins na mapie

```
The map should show red location pins for threats. Each pin is a 32dp circle with a white exclamation mark "!" inside, sitting on a pointed drop-shape. When multiple alerts cluster together, replace individual pins with a single circular cluster marker showing the count (e.g. "5") in white on red background.
```

---

## 3.10 Fix family mode colors

```
On the map, family member avatars should be green (#00C853) circular pins with the child's initial or avatar, clearly distinct from the red threat pins. When viewing family tab, the entire screen tint can lean toward green/blue (calm, safe) instead of red (alarm).
```

---

## 3.11 Fix dark mode

```
The app needs a proper dark mode. Backgrounds become near-black (#121212), cards become slightly lighter grey (#1E1E1E), text becomes white/off-white, but the alert red primary color stays the same and becomes even more prominent. Map switches to a dark street style.
```

---

## 3.12 Fix CTA hierarchy

```
On every screen that has more than one button, ensure only ONE button is filled (the primary action). Secondary actions use outlined style (transparent with border). Tertiary actions are text-only. Never show two filled primary buttons side by side.
```

---

## 3.13 Fix "too corporate" vibe

```
Remove any stock business-style photography. Replace hero images with simple line illustrations or Material icon compositions. The app is community-focused and human — it should feel approachable and friendly, not like a B2B dashboard. Soft shadows, warm neutrals, not stark white.
```

---

## 3.14 Fix "too scary" vibe

```
Reduce the use of red to only: SOS button, Zgłoś button, threat category icons, and error states. Backgrounds, headers, and general UI use calm neutrals and soft blues. The app should feel reassuring, not alarming.
```

---

## 3.15 Fix empty states

```
Every list screen (My Alerts, News, Family, Badges) needs a friendly empty state when there's nothing to show. Structure: a large Material icon (outlined) centered, headline in bold ("Nie masz jeszcze..."), one line of encouraging subtitle, a primary CTA button to take action. Plenty of vertical whitespace.
```

---

## Jeśli nic nie działa

Opuść screen i wróć do niego za godzinę. Czasem Stitch zawiesza się na konkretnym
kontekście. Można też utworzyć **nowy projekt** kopiując design brief i używając
wyostrzonych promptów ze zdobytego doświadczenia.

Ostateczność — eksportuj istniejące screeny przez Stitch MCP (`get_screen_code`,
`get_screen_image`), pobierz HTML + zrzuty, i traktuj je jako referencję przy
ręcznej implementacji Flutter lub Figma.
