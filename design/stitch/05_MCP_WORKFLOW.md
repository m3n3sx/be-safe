# 05 — Stitch MCP Workflow

Jak użyć **Stitch MCP** który dodaliśmy do Kiro, żeby wyciągnąć design
bezpośrednio z terminala (bez klikania w UI Stitcha).

## Wymagania

- ✅ Kiro MCP server `stitch` jest aktywny (sprawdź `/mcp`)
- ✅ `STITCH_API_KEY` w `~/.kiro/settings/mcp.json`
- ✅ Masz wygenerowany design w Stitch Web UI

## Dostępne narzędzia (14)

Po podłączeniu MCP w Kiro wpisz `/mcp` — zobaczysz pełną listę. Kluczowe:

### Upstream Stitch tools (12)
Prawdziwe Stitch API — zarządzanie projektami, screenami, palettą:
- `list_projects` — wszystkie Twoje projekty Stitch
- `get_project <id>` — szczegóły projektu (lista screenów, metadata)
- `list_screens <project_id>` — screeny w projekcie
- `get_screen <screen_id>` — HTML + metadata pojedynczego screena
- `create_project`, `update_project`, `delete_project`
- `create_screen`, `update_screen`, `delete_screen`
- `get_palette`, `update_palette`

### Virtual tools (2)
High-level skróty dodane przez `@_davideast/stitch-mcp`:
- **`build_site`** — mapuje screeny → route'y, generuje Astro site
- **`get_screen_code`** — HTML code screena
- **`get_screen_image`** — PNG screenshot base64

## Przykłady użycia w chat z Kiro

> Uwaga: poniższe to **przykłady rozmów** z tym agentem. Wklej je jako
> wiadomości po załadowaniu stitch MCP.

### Znajdź projekt be:Safe
```
Użyj list_projects i pokaż mi ID projektu "be:Safe".
```

### Wyciągnij wszystkie screeny jako PNG
```
Dla projektu <ID> pobierz wszystkie screeny przez get_screen_image
i zapisz do /home/ooxo/alert/design/stitch-export/screens/ z nazwami
numer_nazwa.png.
```

### Pobierz HTML konkretnego ekranu
```
Pobierz get_screen_code dla screena "Map" z projektu <ID>
i zapisz do /home/ooxo/alert/design/stitch-export/html/01_map.html.
```

### Zbuduj Astro site (jeśli robisz też landing)
```
Zbuduj site z projektu <ID> mapując:
- screen "Home" → /
- screen "About" → /about
- screen "Download" → /download
Użyj build_site.
```

## Workflow: od zera do Flutterowego UI

1. **W Stitch UI** wklej `01_MASTER_PROMPT.md` → generujesz bazę
2. **Iteruj** używając `02_SCREEN_PROMPTS.md` (w UI stitcha)
3. **W Kiro chat** poproś agenta:
   ```
   Pobierz wszystkie screeny projektu be:Safe jako PNG do
   /home/ooxo/alert/design/stitch-export/screens/
   ```
4. **Agent użyje MCP** żeby ściągnąć pliki lokalnie
5. **Otwórz screeny** jako referencję przy pisaniu Flutter UI
6. (opcjonalnie) **Pobierz HTML** i daj agentowi zadanie
   "przepisz ten HTML na Flutter widget"

## Debug

Jeśli MCP nie odpala:
```bash
# sprawdź czy server się łączy
STITCH_API_KEY="[REDACTED_STITCH_API_KEY_TO_ROTATE]" npx -y @_davideast/stitch-mcp proxy

# powinieneś zobaczyć:
# [stitch-proxy] Connecting to https://stitch.googleapis.com/mcp...
# [stitch-proxy] Connected to Stitch, discovered 14 tools
# [stitch-proxy] Proxy server running
```

Jeśli widzisz `StitchProxy requires an API key` — klucz nie doszedł. Sprawdź
`env.STITCH_API_KEY` w `~/.kiro/settings/mcp.json`.

Jeśli widzisz `401 / permission denied` — klucz wygasł lub projekt nie ma
włączonego Stitch API. Odpal:
```bash
gcloud services enable stitch.googleapis.com --project=<id>
gcloud beta services mcp enable stitch.googleapis.com --project=<id>
```

## Uwaga techniczna

Stitch MCP to **tylko proxy** do Google Cloud Stitch API. Tworzenie designu
odbywa się wciąż w UI (`stitch.withgoogle.com`). MCP pozwala **czytać** dane
(screeny, code, palette) ale tworzenie designu przez "prompt API" nie jest
oficjalnie udostępnione jako tool — musisz wklejać prompty w web UI.
