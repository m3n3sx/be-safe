#!/usr/bin/env python3
"""be:Safe v98 — Figma SVG export of all 44 screens.

Mirrors the live app:
- Serenity Guard tokens (design_tokens.dart)
- iOS-style InsetGroupedSection (radius 10) + AppleCard (radius 16)
- SafetyHeroXL hero on Home
- Voltgear voltMint #C7F73E accent on dark pill / progress ring
- Global dock v95+ (6 buttons: Home/Mapa/SOS/Zgłoś/Rodzina/Profil)

Real data: meneswczesny@gmail.com (m3n3s, id 0a397992-115e-465e-b409-429b31690210).
"""
from pathlib import Path
import html

# ── PALETTE ────────────────────────────────────────────────────────────────
COL = {
    "primary":      "#03080E",
    "navy":         "#1A2027",       # primaryContainer
    "mint":         "#9DF4CB",       # Serenity safe-mint
    "aqua":         "#9EEBEC",
    "coral":        "#FF7A7A",
    "voltMint":     "#C7F73E",
    "voltMintInk":  "#1A2206",
    "grouped":      "#F2F2F7",
    "white":        "#FFFFFF",
    "sep":          "#C6C6C8",
    "label2":       "#8E8E93",
    "outline":      "#E5E5EA",
    "red":          "#FF1D25",
    "amber":        "#FFA000",
    "green":        "#1B873A",
}

W, H = 390, 844
COLS = 7
GAP = 80
PAD = 80

# ── REAL DATA ──────────────────────────────────────────────────────────────
USER = {"username": "m3n3s", "display": "Piotr Menes",
        "email": "meneswczesny@gmail.com", "reputation": 104,
        "app_mode": "normal", "joined": "kwiecień 2026",
        "avatar_initial": "M", "ref_code": "M3N3S"}

GROUPS = [
    ("Kasty przychlasty", "64410260", 2),
    ("Grupa1", "BB400AB5", 7),
    ("Grupa", "5E202124", 2),
    ("grupa", "796D3499", 2),
    ("Rodzina Testowa E2E", "E2ETEST", 4),
    ("Babcia Solo", "BABCIA1", 2),
]

MEMBERS = [  # username, role, battery, online_label, online (bool), is_child
    ("Marcin", "parent", 96, "Online", True, False),
    ("piotr", "parent", 98, "Online", True, False),
    ("m3n3s", "parent", 48, "Offline", False, False),
    ("Marek Kołodziejczyk", "parent", 85, "Offline", False, False),
    ("Michael Skweres (Hiki)", "parent", 46, "Offline", False, False),
    ("Heluss Menelek", "child", 98, "Offline", False, True),
    ("Justyna Rewers", "child", 32, "Offline", False, True),
]

ALERTS = [
    ("aggression", "Agresywna grupa pod ratuszem", "wczoraj"),
    ("police", "Zatrzymanie przy ratuszu", "wczoraj"),
    ("police", "Patrol policji na rynku", "wczoraj"),
    ("aggression", "Bójka przed dworcem", "wczoraj"),
    ("other", "Padający słup energetyczny", "wczoraj"),
    ("animal", "Bezpański pies w parku", "wczoraj"),
]

ALERT_ICONS = {
    "aggression": ("⚠️", COL["coral"]),
    "police":     ("🚓", COL["navy"]),
    "animal":     ("🐕", COL["aqua"]),
    "other":      ("📍", COL["label2"]),
    "fire":       ("🔥", COL["red"]),
    "school_zone":("🏫", COL["amber"]),
}

RANKING = [
    ("m3n3s (Ty)", 104, True),
    ("Test", 100, False),
    ("Gość51BB", 100, False),
    ("Tadeusz", 100, False),
    ("AlertBot", 100, False),
    ("Piotr Menes", 100, False),
]

# ── SCREENS LIST ───────────────────────────────────────────────────────────
SCREENS = [
    # name,             section,    kind,         label,                 dart_path
    ("01_onboarding",     "auth",     "splash",     "Onboarding",                  "screens/onboarding/onboarding_screen.dart"),
    ("02_mode_picker",    "auth",     "picker",     "Wybór trybu",                 "screens/mode/mode_picker_screen.dart"),
    ("03_login",          "auth",     "form",       "Logowanie",                   "screens/auth/login_screen.dart"),
    ("04_forgot_password","auth",     "form",       "Zapomniane hasło",            "screens/auth/forgot_password_screen.dart"),
    ("10_home_normal",    "home",     "home",       "Home (Normal)",               "screens/home/home_screen.dart"),
    ("11_home_kids",      "home",     "home_kids",  "Home (Kids)",                 "screens/home/home_kids_screen.dart"),
    ("12_home_senior",    "home",     "home_senior","Home (Senior)",               "screens/home/home_senior_screen.dart"),
    ("20_map",            "map",      "map",        "Mapa",                        "screens/map/map_screen.dart"),
    ("21_alert_detail",   "alerts",   "detail",     "Szczegóły alertu",            "screens/alerts/alert_detail_screen.dart"),
    ("22_alert_create",   "alerts",   "form",       "Zgłoś alert",                 "screens/alerts/create_alert_screen.dart"),
    ("23_alerts_my",      "alerts",   "list_alerts","Moje zgłoszenia",             "screens/alerts/my_alerts_screen.dart"),
    ("24_alerts_stats",   "alerts",   "stats",      "Statystyki",                  "screens/alerts/alert_stats_screen.dart"),
    ("30_family",         "family",   "list_groups","Rodzina",                     "screens/family/family_screen.dart"),
    ("31_family_group",   "family",   "list_members","Grupa1 (członkowie)",        "screens/family/family_group_screen.dart"),
    ("32_family_chat",    "family",   "chat",       "Czat rodzinny",               "screens/family/family_chat_screen.dart"),
    ("33_family_planner", "family",   "list_events","Planner",                     "screens/family/family_planner_screen.dart"),
    ("34_family_sos",     "family",   "sos",        "SOS rodzinny",                "screens/family/family_sos_screen.dart"),
    ("35_member_profile", "family",   "profile_member","Profil Marcin",            "screens/family/member_profile_screen.dart"),
    ("36_child_profile",  "family",   "profile_child", "Profil Heluss",            "screens/family/child_profile_screen.dart"),
    ("37_safe_routes",    "family",   "list_routes","Bezpieczne trasy",            "screens/family/safe_routes_screen.dart"),
    ("38_draw_safe_route","family",   "draw",       "Rysuj trasę",                 "screens/family/draw_safe_route_screen.dart"),
    ("39_add_geofence",   "family",   "draw",       "Strefa geofence",             "screens/family/add_geofence_screen.dart"),
    ("40_location_history","family",  "list_history","Historia lokalizacji",       "screens/family/location_history_screen.dart"),
    ("41_ping_response",  "family",   "detail",     "Odpowiedź na ping",           "screens/family/ping_response_screen.dart"),
    ("50_sos_normal",     "sos",      "sos",        "SOS",                         "screens/sos/sos_screen.dart"),
    ("51_sos_kids",       "sos",      "sos",        "SOS (Kids)",                  "screens/sos/sos_kids_screen.dart"),
    ("52_sos_senior",     "sos",      "sos",        "SOS (Senior)",                "screens/sos/sos_senior_screen.dart"),
    ("60_profile",        "profile",  "profile_self","Profil",                     "screens/profile/profile_screen.dart"),
    ("61_badges",         "profile",  "list_badges","Odznaki",                     "screens/badges/badges_screen.dart"),
    ("62_ranking",        "profile",  "list_ranking","Ranking",                    "screens/ranking/ranking_screen.dart"),
    ("63_referral",       "profile",  "referral",   "Poleć znajomym",              "screens/referral/referral_screen.dart"),
    ("70_settings",       "settings", "list_settings","Ustawienia",                "screens/settings/settings_screen.dart"),
    ("71_permissions",    "settings", "list_perms", "Uprawnienia",                 "screens/permissions/permissions_screen.dart"),
    ("72_parental_controls","settings","list_simple","Kontrola rodzicielska",      "screens/parental_controls/parental_controls_screen.dart"),
    ("80_safety_guide",   "safety",   "list_simple","Poradnik bezpieczeństwa",     "screens/safety/safety_guide_screen.dart"),
    ("81_emergency_numbers","safety", "list_simple","Numery alarmowe",             "screens/emergency/emergency_numbers_screen.dart"),
    ("82_cyber_safety",   "safety",   "list_simple","Cyberbezpieczeństwo",         "screens/cyber_safety/cyber_safety_screen.dart"),
    ("83_mental_health_sos","safety", "list_simple","Pomoc psychiczna",            "screens/mental_health/mental_health_sos_screen.dart"),
    ("90_news",           "community","list_simple","Aktualności",                 "screens/community/news_screen.dart"),
    ("a0_escort",         "extras",   "form",       "Eskorta",                     "screens/escort/escort_screen.dart"),
    ("a1_fake_call_setup","extras",   "form",       "Fałszywy telefon",            "screens/fake_call/fake_call_setup_screen.dart"),
    ("a2_fake_call_incoming","extras","detail",     "Przychodzące połączenie",     "screens/fake_call/fake_call_incoming_screen.dart"),
    ("a3_pets",           "extras",   "list_simple","Zwierzaki",                   "screens/pets/pets_screen.dart"),
    ("b0_legal",          "legal",    "list_simple","Polityka prywatności",        "screens/legal/privacy_screen.dart"),
]

# ── SVG BUILDERS ───────────────────────────────────────────────────────────

def esc(s): return html.escape(str(s)) if s else ""

def status_bar(y=0):
    return f'''
<g class="status-bar">
  <rect x="0" y="{y}" width="{W}" height="44" fill="{COL["grouped"]}"/>
  <text x="20" y="{y+28}" font-family="Inter" font-size="15" font-weight="600" fill="{COL["primary"]}">9:41</text>
  <g transform="translate(335,{y+18})">
    <rect x="0" y="0" width="24" height="11" rx="2.5" fill="none" stroke="{COL["primary"]}" stroke-width="1"/>
    <rect x="2" y="2" width="18" height="7" fill="{COL["primary"]}"/>
    <rect x="25" y="3" width="1.5" height="5" fill="{COL["primary"]}"/>
  </g>
</g>'''

def app_bar(title, y=44, has_back=True, large=False):
    if large:
        return f'''
<g class="app-bar-large">
  <text x="20" y="{y+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">{esc(title)}</text>
</g>'''
    back = f'<text x="20" y="{y+34}" font-family="Inter" font-size="22" fill="{COL["primary"]}">‹</text>' if has_back else ""
    title_x = 50 if has_back else 20
    return f'''
<g class="app-bar">
  {back}
  <text x="{title_x}" y="{y+34}" font-family="Inter" font-size="17" font-weight="600" fill="{COL["primary"]}">{esc(title)}</text>
</g>'''

def dock(y=H-86):
    """Global dock v95+: 6 buttons, Zgłoś transparent with red 24px circle."""
    bar_h = 64
    bar_y = y
    items = [
        ("home",   "Home",    "▣"),  # SVG placeholder, real app uses dock.svg
        ("map",    "Mapa",    "🗺"),
        ("sos",    "SOS",     "⛑"),
        ("report", "Zgłoś",   "+"),  # special: red circle
        ("family", "Rodzina", "👨‍👩‍👧"),
        ("prof",   "Profil",  "👤"),
    ]
    out = [f'<rect x="8" y="{bar_y}" width="{W-16}" height="{bar_h}" rx="22" fill="{COL["navy"]}"/>']
    item_w = (W - 16) / 6
    active_idx = 0  # home active by default; can vary per screen
    for i, (key, label, glyph) in enumerate(items):
        cx = 8 + item_w * i + item_w / 2
        if key == "report":
            # red circle 24px with white plus + border
            out.append(f'<circle cx="{cx}" cy="{bar_y+24}" r="12" fill="{COL["red"]}" stroke="{COL["white"]}" stroke-width="2"/>')
            out.append(f'<text x="{cx}" y="{bar_y+29}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="700" fill="{COL["white"]}">+</text>')
            out.append(f'<text x="{cx}" y="{bar_y+54}" text-anchor="middle" font-family="Inter" font-size="11" font-weight="500" fill="{COL["white"]}">{label}</text>')
        else:
            color = COL["white"] if i == active_idx else "#ffffff8c"
            out.append(f'<text x="{cx}" y="{bar_y+28}" text-anchor="middle" font-family="Inter" font-size="18" fill="{color}">{glyph}</text>')
            out.append(f'<text x="{cx}" y="{bar_y+54}" text-anchor="middle" font-family="Inter" font-size="11" font-weight="500" fill="{color}">{label}</text>')
    return "<g class='dock'>" + "\n".join(out) + "</g>"

# ── INDIVIDUAL SCREEN BODIES ────────────────────────────────────────────────

def body_home(y0):
    """SafetyHeroXL + activity stack + AQI widget."""
    out = []
    # Top bar: avatar + name
    out.append(f'<text x="20" y="{y0+30}" font-family="Inter" font-size="13" font-weight="500" letter-spacing="0.5" fill="{COL["label2"]}">CZEŚĆ</text>')
    out.append(f'<text x="20" y="{y0+58}" font-family="Inter" font-size="22" font-weight="700" fill="{COL["primary"]}">Piotr Menes</text>')
    out.append(f'<circle cx="{W-32}" cy="{y0+44}" r="20" fill="{COL["mint"]}"/>')
    out.append(f'<text x="{W-32}" y="{y0+50}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="700" fill="{COL["primary"]}">M</text>')

    # SafetyHeroXL: 296pt ring
    cx, cy = W/2, y0 + 220
    out.append(f'<text x="{cx}" y="{y0+96}" text-anchor="middle" font-family="Inter" font-size="34" font-weight="200" fill="{COL["primary"]}">Wszystko</text>')
    out.append(f'<text x="{cx}" y="{y0+130}" text-anchor="middle" font-family="Inter" font-size="34" font-weight="200" fill="{COL["primary"]}">w porządku</text>')
    out.append(f'<text x="{cx}" y="{y0+155}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["label2"]}">Twoja okolica jest bezpieczna</text>')

    # Ring (mint with voltMint accent at progress end)
    r = 110
    out.append(f'<defs><linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{COL["mint"]}"/><stop offset="1" stop-color="{COL["voltMint"]}"/></linearGradient></defs>')
    # Glow halo
    out.append(f'<circle cx="{cx}" cy="{cy+40}" r="{r+12}" fill="{COL["mint"]}" fill-opacity="0.18"/>')
    out.append(f'<circle cx="{cx}" cy="{cy+40}" r="{r}" fill="none" stroke="{COL["sep"]}" stroke-width="18" stroke-opacity="0.3"/>')
    out.append(f'<circle cx="{cx}" cy="{cy+40}" r="{r}" fill="none" stroke="url(#ringGrad)" stroke-width="18" stroke-linecap="round" transform="rotate(-90 {cx} {cy+40})"/>')
    out.append(f'<text x="{cx}" y="{cy+38}" text-anchor="middle" font-family="Inter" font-size="10" font-weight="600" letter-spacing="1.4" fill="{COL["label2"]}">POZIOM BEZPIECZEŃSTWA</text>')
    out.append(f'<text x="{cx-10}" y="{cy+80}" text-anchor="middle" font-family="Inter" font-size="80" font-weight="100" letter-spacing="-3" fill="{COL["primary"]}">10</text>')
    out.append(f'<text x="{cx+38}" y="{cy+80}" text-anchor="middle" font-family="Inter" font-size="20" font-weight="300" fill="{COL["label2"]}">/ 10</text>')

    # Sub-pill
    pill_y = cy + 175
    out.append(f'<rect x="{W/2-90}" y="{pill_y}" width="180" height="28" rx="14" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{cx}" y="{pill_y+18}" text-anchor="middle" font-family="Inter" font-size="12" font-weight="500" fill="{COL["white"]}">Brak alertów · sprawdź mapę</text>')

    # AQI card
    aqi_y = y0 + 460
    out.append(f'<rect x="20" y="{aqi_y}" width="{W-40}" height="72" rx="16" fill="{COL["white"]}"/>')
    out.append(f'<circle cx="48" cy="{aqi_y+36}" r="16" fill="{COL["mint"]}" fill-opacity="0.4"/>')
    out.append(f'<text x="48" y="{aqi_y+41}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["primary"]}">🌬</text>')
    out.append(f'<text x="76" y="{aqi_y+30}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">Jakość powietrza</text>')
    out.append(f'<text x="76" y="{aqi_y+50}" font-family="Inter" font-size="13" fill="{COL["label2"]}">Bardzo dobra · PM2.5: 8 µg/m³</text>')
    out.append(f'<text x="{W-32}" y="{aqi_y+44}" text-anchor="end" font-family="Inter" font-size="28" font-weight="300" fill="{COL["green"]}">12</text>')

    # Activity section header
    out.append(f'<text x="20" y="{y0+580}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">DZISIEJSZA AKTYWNOŚĆ</text>')
    return "\n".join(out)


def body_login(y0):
    out = []
    out.append(f'<text x="20" y="{y0+100}" font-family="Inter" font-size="32" font-weight="200" fill="{COL["primary"]}">Witaj ponownie</text>')
    out.append(f'<text x="20" y="{y0+130}" font-family="Inter" font-size="14" fill="{COL["label2"]}">Zaloguj się, by chronić bliskich</text>')
    # Email field
    out.append(f'<rect x="20" y="{y0+180}" width="{W-40}" height="56" rx="14" fill="{COL["white"]}"/>')
    out.append(f'<text x="36" y="{y0+200}" font-family="Inter" font-size="11" fill="{COL["label2"]}">Email</text>')
    out.append(f'<text x="36" y="{y0+222}" font-family="Inter" font-size="16" fill="{COL["primary"]}">meneswczesny@gmail.com</text>')
    # Password
    out.append(f'<rect x="20" y="{y0+252}" width="{W-40}" height="56" rx="14" fill="{COL["white"]}"/>')
    out.append(f'<text x="36" y="{y0+272}" font-family="Inter" font-size="11" fill="{COL["label2"]}">Hasło</text>')
    out.append(f'<text x="36" y="{y0+294}" font-family="Inter" font-size="16" fill="{COL["primary"]}">●●●●●●●●</text>')
    # CTA
    out.append(f'<rect x="20" y="{y0+340}" width="{W-40}" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{W/2}" y="{y0+376}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="600" fill="{COL["white"]}">Zaloguj się</text>')
    # Google
    out.append(f'<rect x="20" y="{y0+410}" width="{W-40}" height="56" rx="28" fill="{COL["white"]}" stroke="{COL["outline"]}"/>')
    out.append(f'<text x="{W/2}" y="{y0+446}" text-anchor="middle" font-family="Inter" font-size="15" font-weight="500" fill="{COL["primary"]}">Zaloguj przez Google</text>')
    out.append(f'<text x="{W/2}" y="{y0+520}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["label2"]}">Nie masz konta? <tspan font-weight="600" fill="{COL["primary"]}">Zarejestruj się</tspan></text>')
    return "\n".join(out)

def body_onboarding(y0):
    out = []
    cx = W/2
    out.append(f'<circle cx="{cx}" cy="{y0+200}" r="120" fill="{COL["mint"]}" fill-opacity="0.6"/>')
    out.append(f'<circle cx="{cx}" cy="{y0+200}" r="80" fill="{COL["aqua"]}" fill-opacity="0.8"/>')
    out.append(f'<text x="{cx}" y="{y0+215}" text-anchor="middle" font-family="Inter" font-size="60" fill="{COL["white"]}">🛡</text>')
    out.append(f'<text x="{cx}" y="{y0+400}" text-anchor="middle" font-family="Inter" font-size="28" font-weight="300" fill="{COL["primary"]}">Witaj w be:Safe</text>')
    out.append(f'<text x="{cx}" y="{y0+430}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["label2"]}">Twoja spokojna strefa</text>')
    out.append(f'<text x="{cx}" y="{y0+450}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["label2"]}">bezpieczeństwa</text>')
    # dots
    for i in range(5):
        c = COL["primary"] if i == 0 else COL["sep"]
        out.append(f'<circle cx="{cx + (i-2)*16}" cy="{y0+520}" r="4" fill="{c}"/>')
    # CTA Dalej
    out.append(f'<rect x="20" y="{y0+620}" width="{W-40}" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{cx}" y="{y0+656}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="600" fill="{COL["white"]}">Dalej</text>')
    out.append(f'<text x="{W-20}" y="{y0+30}" text-anchor="end" font-family="Inter" font-size="15" font-weight="500" fill="{COL["label2"]}">Pomiń</text>')
    return "\n".join(out)

def body_picker(y0):
    out = []
    cx = W/2
    out.append(f'<text x="20" y="{y0+90}" font-family="Inter" font-size="32" font-weight="200" fill="{COL["primary"]}">Wybierz tryb</text>')
    out.append(f'<text x="20" y="{y0+118}" font-family="Inter" font-size="14" fill="{COL["label2"]}">Dla kogo używasz be:Safe?</text>')
    cards = [
        ("Dla dziecka", "Tryb kids 7-12 lat", "🧒", COL["aqua"]),
        ("Dla seniora", "Duże ikony, prosty układ", "👵", COL["mint"]),
        ("Standardowy", "Pełne funkcje (13-59 lat)", "👤", COL["voltMint"]),
    ]
    for i, (title, sub, emoji, glow) in enumerate(cards):
        ty = y0 + 160 + i*160
        out.append(f'<rect x="20" y="{ty}" width="{W-40}" height="140" rx="22" fill="{COL["white"]}"/>')
        out.append(f'<circle cx="{W-60}" cy="{ty+38}" r="40" fill="{glow}" fill-opacity="0.35"/>')
        out.append(f'<text x="{W-60}" y="{ty+50}" text-anchor="middle" font-size="32">{emoji}</text>')
        out.append(f'<text x="32" y="{ty+50}" font-family="Inter" font-size="20" font-weight="600" fill="{COL["primary"]}">{title}</text>')
        out.append(f'<text x="32" y="{ty+76}" font-family="Inter" font-size="14" fill="{COL["label2"]}">{sub}</text>')
        out.append(f'<text x="32" y="{ty+114}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">Wybierz →</text>')
    return "\n".join(out)

def body_form(y0, title, sub, fields, cta):
    out = []
    out.append(f'<text x="20" y="{y0+30}" font-family="Inter" font-size="28" font-weight="300" fill="{COL["primary"]}">{esc(title)}</text>')
    out.append(f'<text x="20" y="{y0+58}" font-family="Inter" font-size="14" fill="{COL["label2"]}">{esc(sub)}</text>')
    fy = y0 + 100
    for label, value in fields:
        out.append(f'<rect x="20" y="{fy}" width="{W-40}" height="56" rx="14" fill="{COL["white"]}"/>')
        out.append(f'<text x="36" y="{fy+20}" font-family="Inter" font-size="11" fill="{COL["label2"]}">{esc(label)}</text>')
        out.append(f'<text x="36" y="{fy+42}" font-family="Inter" font-size="16" fill="{COL["primary"]}">{esc(value)}</text>')
        fy += 72
    out.append(f'<rect x="20" y="{fy+12}" width="{W-40}" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{W/2}" y="{fy+48}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="600" fill="{COL["white"]}">{esc(cta)}</text>')
    return "\n".join(out)

def body_list_groups(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Rodzina</text>')
    out.append(f'<text x="20" y="{y0+118}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">TWOJE GRUPY</text>')
    cy = y0 + 138
    # InsetGroupedSection card
    card_h = 56 * len(GROUPS) + 1
    out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="{card_h}" rx="10" fill="{COL["white"]}"/>')
    for i, (name, code, members) in enumerate(GROUPS):
        ry = cy + i * 56
        # Icon
        out.append(f'<rect x="32" y="{ry+12}" width="28" height="28" rx="7" fill="{COL["navy"]}"/>')
        out.append(f'<text x="46" y="{ry+31}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["white"]}">👨</text>')
        # Title
        out.append(f'<text x="72" y="{ry+28}" font-family="Inter" font-size="17" fill="{COL["primary"]}">{esc(name)}</text>')
        out.append(f'<text x="72" y="{ry+46}" font-family="Inter" font-size="13" fill="{COL["label2"]}">{members} osób · kod {code}</text>')
        # Chevron
        out.append(f'<text x="{W-32}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
        if i < len(GROUPS) - 1:
            out.append(f'<line x1="72" y1="{ry+55}" x2="{W-16}" y2="{ry+55}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    # CTA
    out.append(f'<rect x="20" y="{y0+560}" width="{W-40}" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{W/2}" y="{y0+596}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="600" fill="{COL["white"]}">+ Stwórz nową grupę</text>')
    return "\n".join(out)

def body_list_members(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Grupa1</text>')
    out.append(f'<text x="20" y="{y0+88}" font-family="Inter" font-size="13" fill="{COL["label2"]}">7 członków · kod BB400AB5</text>')
    out.append(f'<text x="20" y="{y0+128}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">CZŁONKOWIE</text>')
    cy = y0 + 148
    card_h = 64 * len(MEMBERS) + 1
    out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="{card_h}" rx="10" fill="{COL["white"]}"/>')
    for i, (username, role, batt, status, online, is_child) in enumerate(MEMBERS):
        ry = cy + i * 64
        # Avatar
        avatar_color = COL["coral"] if is_child else COL["mint"]
        out.append(f'<circle cx="46" cy="{ry+32}" r="20" fill="{avatar_color}" fill-opacity="0.6"/>')
        out.append(f'<text x="46" y="{ry+38}" text-anchor="middle" font-family="Inter" font-size="15" font-weight="700" fill="{COL["primary"]}">{username[0].upper()}</text>')
        if online:
            out.append(f'<circle cx="60" cy="{ry+46}" r="5" fill="{COL["green"]}" stroke="{COL["white"]}" stroke-width="2"/>')
        # Name + role
        out.append(f'<text x="78" y="{ry+30}" font-family="Inter" font-size="16" font-weight="600" fill="{COL["primary"]}">{esc(username)}</text>')
        role_color = COL["coral"] if is_child else COL["label2"]
        out.append(f'<text x="78" y="{ry+50}" font-family="Inter" font-size="13" fill="{role_color}">{role} · 🔋 {batt}% · {status}</text>')
        out.append(f'<text x="{W-32}" y="{ry+38}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
        if i < len(MEMBERS) - 1:
            out.append(f'<line x1="78" y1="{ry+63}" x2="{W-16}" y2="{ry+63}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    return "\n".join(out)

def body_chat(y0):
    out = []
    out.append(f'<text x="20" y="{y0+30}" font-family="Inter" font-size="20" font-weight="600" fill="{COL["primary"]}">Grupa1</text>')
    out.append(f'<text x="20" y="{y0+50}" font-family="Inter" font-size="12" fill="{COL["label2"]}">7 osób · Heluss pisze...</text>')
    msgs = [
        ("Marcin", "Heluss już idzie ze szkoły?", False, "14:32"),
        ("Heluss", "Idę ze szkoły", False, "14:35"),
        ("Ty",     "OK, daj znać jak będziesz w domu 💙", True,  "14:36"),
        ("Justyna","Trening do 17 dzisiaj", False, "15:02"),
        ("Ty",     "Wezmę Heluss z drogi", True,  "15:03"),
    ]
    my = y0 + 80
    for name, txt, mine, t in msgs:
        bg = COL["mint"] if mine else COL["white"]
        fg = COL["primary"]
        align_x = W - 220 if mine else 16
        width = 200
        h = 56
        out.append(f'<rect x="{align_x}" y="{my}" width="{width}" height="{h}" rx="16" fill="{bg}"/>')
        if not mine:
            out.append(f'<text x="{align_x+16}" y="{my+18}" font-family="Inter" font-size="11" font-weight="600" fill="{COL["label2"]}">{esc(name)}</text>')
            out.append(f'<text x="{align_x+16}" y="{my+38}" font-family="Inter" font-size="14" fill="{fg}">{esc(txt)}</text>')
        else:
            out.append(f'<text x="{align_x+16}" y="{my+22}" font-family="Inter" font-size="14" fill="{fg}">{esc(txt)}</text>')
        out.append(f'<text x="{align_x+16}" y="{my+52}" font-family="Inter" font-size="10" fill="{COL["label2"]}">{t}</text>')
        my += h + 12
    # input bar
    iy = H - 86 - 80
    out.append(f'<rect x="16" y="{iy}" width="{W-110}" height="48" rx="24" fill="{COL["white"]}"/>')
    out.append(f'<text x="32" y="{iy+30}" font-family="Inter" font-size="14" fill="{COL["label2"]}">Wiadomość...</text>')
    out.append(f'<circle cx="{W-50}" cy="{iy+24}" r="22" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{W-50}" y="{iy+30}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["white"]}">▲</text>')
    return "\n".join(out)

def body_sos(y0, mode="normal"):
    out = []
    cx = W/2
    headline = {"normal": "Czy potrzebujesz pomocy?", "kids": "Potrzebujesz pomocy?", "senior": "Wezwij pomoc"}[mode] if mode in ("normal","kids","senior") else "Czy potrzebujesz pomocy?"
    out.append(f'<text x="{cx}" y="{y0+50}" text-anchor="middle" font-family="Inter" font-size="22" font-weight="300" fill="{COL["primary"]}">{esc(headline)}</text>')
    out.append(f'<text x="{cx}" y="{y0+76}" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["label2"]}">Trzymaj przycisk przez 2 sekundy</text>')
    # SOS orb
    cy = y0 + 280
    out.append(f'<circle cx="{cx}" cy="{cy}" r="160" fill="{COL["coral"]}" fill-opacity="0.18"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="120" fill="{COL["coral"]}" fill-opacity="0.35"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="90" fill="{COL["coral"]}"/>')
    out.append(f'<text x="{cx}" y="{cy+15}" text-anchor="middle" font-family="Inter" font-size="42" font-weight="700" fill="{COL["white"]}">SOS</text>')
    # Cards: Fake call + Escort
    cy2 = y0 + 480
    out.append(f'<rect x="20" y="{cy2}" width="{(W-50)/2}" height="80" rx="16" fill="{COL["white"]}"/>')
    out.append(f'<text x="36" y="{cy2+28}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">📞 Fałszywy</text>')
    out.append(f'<text x="36" y="{cy2+48}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">telefon</text>')
    out.append(f'<text x="36" y="{cy2+68}" font-family="Inter" font-size="11" fill="{COL["label2"]}">Awaryjna wymówka</text>')
    out.append(f'<rect x="{30+(W-50)/2}" y="{cy2}" width="{(W-50)/2}" height="80" rx="16" fill="{COL["white"]}"/>')
    out.append(f'<text x="{46+(W-50)/2}" y="{cy2+28}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">👀 Eskorta</text>')
    out.append(f'<text x="{46+(W-50)/2}" y="{cy2+48}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">Follow Me</text>')
    out.append(f'<text x="{46+(W-50)/2}" y="{cy2+68}" font-family="Inter" font-size="11" fill="{COL["label2"]}">Bliscy śledzą</text>')
    # Cancel
    out.append(f'<text x="{cx}" y="{y0+620}" text-anchor="middle" font-family="Inter" font-size="14" font-weight="500" fill="{COL["label2"]}">Anuluj</text>')
    return "\n".join(out)

def body_profile_self(y0):
    out = []
    cx = W/2
    # Top bar
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Profil</text>')
    # Hero AppleCard
    hy = y0 + 100
    out.append(f'<rect x="16" y="{hy}" width="{W-32}" height="120" rx="16" fill="{COL["white"]}"/>')
    out.append(f'<circle cx="64" cy="{hy+60}" r="32" fill="{COL["mint"]}"/>')
    out.append(f'<text x="64" y="{hy+70}" text-anchor="middle" font-family="Inter" font-size="24" font-weight="700" fill="{COL["primary"]}">M</text>')
    out.append(f'<text x="112" y="{hy+50}" font-family="Inter" font-size="18" font-weight="700" fill="{COL["primary"]}">Piotr Menes</text>')
    out.append(f'<text x="112" y="{hy+72}" font-family="Inter" font-size="13" fill="{COL["label2"]}">{esc(USER["email"])}</text>')
    out.append(f'<text x="112" y="{hy+92}" font-family="Inter" font-size="13" fill="{COL["label2"]}">⭐ {USER["reputation"]} pkt reputacji</text>')
    # Stats row
    sy = y0 + 240
    stats = [("Reputacja", "104"), ("Rodzina", "6 grup"), ("Zgłoszenia", "8")]
    for i,(lbl,val) in enumerate(stats):
        x = 16 + i*(W-32)/3 + 4
        w = (W-48)/3
        out.append(f'<rect x="{x}" y="{sy}" width="{w}" height="76" rx="16" fill="{COL["white"]}"/>')
        out.append(f'<text x="{x+w/2}" y="{sy+34}" text-anchor="middle" font-family="Inter" font-size="22" font-weight="700" fill="{COL["primary"]}">{val}</text>')
        out.append(f'<text x="{x+w/2}" y="{sy+58}" text-anchor="middle" font-family="Inter" font-size="11" fill="{COL["label2"]}">{lbl}</text>')
    # Sections InsetGroupedSection
    cy0 = y0 + 340
    out.append(f'<text x="20" y="{cy0}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">KONTO</text>')
    cy0 += 16
    items = [("👤", "Dane konta", ""), ("🎯", "Promień powiadomień", "500m"), ("📍", "Udostępnij lokalizację", "")]
    out.append(f'<rect x="16" y="{cy0}" width="{W-32}" height="{56*len(items)+1}" rx="10" fill="{COL["white"]}"/>')
    for i,(emoji,title,val) in enumerate(items):
        ry = cy0 + i*56
        out.append(f'<text x="32" y="{ry+34}" font-family="Inter" font-size="18">{emoji}</text>')
        out.append(f'<text x="68" y="{ry+34}" font-family="Inter" font-size="17" fill="{COL["primary"]}">{esc(title)}</text>')
        if val:
            out.append(f'<text x="{W-46}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="15" fill="{COL["label2"]}">{esc(val)}</text>')
        out.append(f'<text x="{W-32}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
        if i < len(items)-1:
            out.append(f'<line x1="68" y1="{ry+55}" x2="{W-16}" y2="{ry+55}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    return "\n".join(out)

def body_alerts_list(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Moje zgłoszenia</text>')
    out.append(f'<text x="20" y="{y0+88}" font-family="Inter" font-size="13" fill="{COL["label2"]}">{len(ALERTS)} alertów</text>')
    cy = y0 + 120
    for i,(cat,title,when) in enumerate(ALERTS):
        ay = cy + i*92
        emoji, color = ALERT_ICONS.get(cat, ("📍", COL["label2"]))
        out.append(f'<rect x="16" y="{ay}" width="{W-32}" height="80" rx="16" fill="{COL["white"]}"/>')
        out.append(f'<circle cx="48" cy="{ay+40}" r="20" fill="{color}" fill-opacity="0.2"/>')
        out.append(f'<text x="48" y="{ay+47}" text-anchor="middle" font-size="18">{emoji}</text>')
        out.append(f'<text x="80" y="{ay+30}" font-family="Inter" font-size="15" font-weight="600" fill="{COL["primary"]}">{esc(title[:32])}</text>')
        out.append(f'<text x="80" y="{ay+50}" font-family="Inter" font-size="12" fill="{COL["label2"]}">{cat} · {when}</text>')
        out.append(f'<text x="80" y="{ay+68}" font-family="Inter" font-size="12" font-weight="600" fill="{COL["green"]}">✓ Aktywny</text>')
        out.append(f'<text x="{W-32}" y="{ay+44}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
    return "\n".join(out)

def body_map(y0):
    out = []
    # Map background (mocked Google Maps)
    out.append(f'<rect x="0" y="{y0}" width="{W}" height="{H-y0-86}" fill="#E8EAED"/>')
    # Roads
    out.append(f'<path d="M0,{y0+200} Q{W/2},{y0+250} {W},{y0+180}" stroke="{COL["white"]}" stroke-width="8" fill="none"/>')
    out.append(f'<path d="M{W/2},{y0} L{W/2+30},{H-86}" stroke="{COL["white"]}" stroke-width="6" fill="none"/>')
    out.append(f'<path d="M0,{y0+400} L{W},{y0+450}" stroke="{COL["white"]}" stroke-width="5" fill="none"/>')
    # Park
    out.append(f'<rect x="{W-130}" y="{y0+50}" width="100" height="80" rx="8" fill="#C8E6C9"/>')
    # User position
    cx, cy = W/2, y0+300
    out.append(f'<circle cx="{cx}" cy="{cy}" r="22" fill="{COL["aqua"]}" fill-opacity="0.5"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="11" fill="{COL["navy"]}" stroke="{COL["white"]}" stroke-width="3"/>')
    # 3 alert pins
    pins = [(80, y0+200, COL["coral"], "⚠"), (W-100, y0+150, COL["coral"], "⚠"), (W-130, y0+450, COL["navy"], "🚓")]
    for px,py,c,g in pins:
        out.append(f'<path d="M{px},{py-26} Q{px-18},{py-12} {px-12},{py-2} L{px},{py+8} L{px+12},{py-2} Q{px+18},{py-12} {px},{py-26} Z" fill="{c}"/>')
        out.append(f'<circle cx="{px}" cy="{py-14}" r="9" fill="{COL["white"]}"/>')
        out.append(f'<text x="{px}" y="{py-10}" text-anchor="middle" font-size="10" font-weight="700" fill="{c}">!</text>')
    # Top search bar
    out.append(f'<rect x="16" y="{y0+12}" width="{W-32}" height="48" rx="24" fill="{COL["white"]}"/>')
    out.append(f'<text x="32" y="{y0+42}" font-family="Inter" font-size="14" fill="{COL["label2"]}">🔍 Szukaj w okolicy...</text>')
    # FAB+
    out.append(f'<circle cx="{W-36}" cy="{H-160}" r="28" fill="{COL["red"]}"/>')
    out.append(f'<text x="{W-36}" y="{H-153}" text-anchor="middle" font-family="Inter" font-size="32" font-weight="300" fill="{COL["white"]}">+</text>')
    return "\n".join(out)

def body_ranking(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Ranking</text>')
    out.append(f'<text x="20" y="{y0+88}" font-family="Inter" font-size="13" fill="{COL["label2"]}">Twoja pozycja: #1 · 104 pkt</text>')
    cy = y0 + 120
    out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="{72*len(RANKING)+1}" rx="16" fill="{COL["white"]}"/>')
    medals = ["🥇","🥈","🥉","4.","5.","6."]
    for i,(name,score,me) in enumerate(RANKING):
        ry = cy + i*72
        out.append(f'<text x="32" y="{ry+44}" font-family="Inter" font-size="18">{medals[i]}</text>')
        out.append(f'<circle cx="80" cy="{ry+36}" r="20" fill="{COL["mint"]}" fill-opacity="0.5"/>')
        out.append(f'<text x="80" y="{ry+42}" text-anchor="middle" font-family="Inter" font-size="14" font-weight="700" fill="{COL["primary"]}">{name[0].upper()}</text>')
        weight = "700" if me else "500"
        bg_color = COL["voltMint"] if me else None
        if bg_color:
            out.append(f'<rect x="20" y="{ry+8}" width="{W-40}" height="56" rx="14" fill="{bg_color}" fill-opacity="0.25"/>')
        out.append(f'<text x="116" y="{ry+34}" font-family="Inter" font-size="16" font-weight="{weight}" fill="{COL["primary"]}">{esc(name)}</text>')
        out.append(f'<text x="116" y="{ry+54}" font-family="Inter" font-size="12" fill="{COL["label2"]}">{score} pkt</text>')
        out.append(f'<text x="{W-32}" y="{ry+44}" text-anchor="end" font-family="Inter" font-size="20" font-weight="600" fill="{COL["primary"]}">{score}</text>')
        if i < len(RANKING)-1:
            out.append(f'<line x1="116" y1="{ry+71}" x2="{W-16}" y2="{ry+71}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    return "\n".join(out)

def body_badges(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Odznaki</text>')
    badges = [
        ("🛡", "Strażnik", "Pierwsze zgłoszenie", True),
        ("👨‍👩‍👧", "Opiekun", "5 osób w rodzinie", True),
        ("📍", "Eksplorator", "10 alertów potwierdzonych", True),
        ("🏆", "Lider okolicy", "Top 10 w Twoim mieście", True),
        ("🌟", "100 pkt reputacji", "Osiągnij 100 pkt", True),
        ("🎯", "Mistrz precyzji", "20 trafnych alertów", False),
    ]
    cy = y0 + 100
    for i,(emoji,name,desc,earned) in enumerate(badges):
        col = i % 2
        row = i // 2
        x = 16 + col*((W-32)/2 + 8)
        w = (W-48)/2
        y = cy + row*120
        out.append(f'<rect x="{x}" y="{y}" width="{w}" height="108" rx="16" fill="{COL["white"]}"/>')
        glow = COL["mint"] if earned else COL["sep"]
        out.append(f'<circle cx="{x+w/2}" cy="{y+34}" r="22" fill="{glow}" fill-opacity="0.5"/>')
        out.append(f'<text x="{x+w/2}" y="{y+42}" text-anchor="middle" font-size="22">{emoji}</text>')
        out.append(f'<text x="{x+w/2}" y="{y+74}" text-anchor="middle" font-family="Inter" font-size="13" font-weight="600" fill="{COL["primary"]}">{esc(name)}</text>')
        out.append(f'<text x="{x+w/2}" y="{y+92}" text-anchor="middle" font-family="Inter" font-size="10" fill="{COL["label2"]}">{esc(desc)}</text>')
    return "\n".join(out)

def body_settings(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Ustawienia</text>')
    sections = [
        ("KONTO", [("👤", "Nazwa użytkownika", "m3n3s"), ("📧", "Email", USER["email"][:18]+"..."), ("📱", "Telefon", "Dodaj")]),
        ("WYGLĄD", [("🎨", "Tryb ciemny", "Jasny"), ("🌍", "Język", "Polski"), ("👤", "Tryb aplikacji", "Standardowy")]),
        ("PRYWATNOŚĆ", [("🔔", "Powiadomienia", "Włączone"), ("🛡", "Uprawnienia", ""), ("👁", "Prywatność", "")]),
    ]
    cy = y0 + 100
    for header, items in sections:
        out.append(f'<text x="20" y="{cy+16}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">{header}</text>')
        cy += 30
        ch = 56*len(items)+1
        out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="{ch}" rx="10" fill="{COL["white"]}"/>')
        for i,(emoji,title,val) in enumerate(items):
            ry = cy + i*56
            out.append(f'<text x="32" y="{ry+34}" font-family="Inter" font-size="16">{emoji}</text>')
            out.append(f'<text x="64" y="{ry+34}" font-family="Inter" font-size="17" fill="{COL["primary"]}">{esc(title)}</text>')
            if val:
                out.append(f'<text x="{W-46}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="15" fill="{COL["label2"]}">{esc(val)}</text>')
            out.append(f'<text x="{W-32}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
            if i < len(items)-1:
                out.append(f'<line x1="64" y1="{ry+55}" x2="{W-16}" y2="{ry+55}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
        cy += ch + 24
    return "\n".join(out)

def body_simple_list(y0, title, items):
    """Generic InsetGroupedSection list (icon, title, subtitle)."""
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">{esc(title)}</text>')
    cy = y0 + 110
    ch = 64 * len(items) + 1
    out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="{ch}" rx="10" fill="{COL["white"]}"/>')
    for i,(emoji,tt,sub) in enumerate(items):
        ry = cy + i*64
        out.append(f'<text x="32" y="{ry+38}" font-family="Inter" font-size="20">{emoji}</text>')
        out.append(f'<text x="72" y="{ry+30}" font-family="Inter" font-size="16" font-weight="500" fill="{COL["primary"]}">{esc(tt)}</text>')
        out.append(f'<text x="72" y="{ry+50}" font-family="Inter" font-size="12" fill="{COL["label2"]}">{esc(sub)}</text>')
        out.append(f'<text x="{W-32}" y="{ry+40}" text-anchor="end" font-family="Inter" font-size="20" fill="{COL["label2"]}">›</text>')
        if i < len(items)-1:
            out.append(f'<line x1="72" y1="{ry+63}" x2="{W-16}" y2="{ry+63}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    return "\n".join(out)

def body_detail(y0, title, desc, hero_color, hero_label="Szczegóły"):
    out = []
    # Hero
    hy = y0 + 100
    out.append(f'<rect x="16" y="{hy}" width="{W-32}" height="180" rx="16" fill="{hero_color}"/>')
    out.append(f'<circle cx="64" cy="{hy+60}" r="32" fill="{COL["white"]}" fill-opacity="0.3"/>')
    out.append(f'<text x="64" y="{hy+70}" text-anchor="middle" font-size="28">⚠</text>')
    out.append(f'<text x="116" y="{hy+56}" font-family="Inter" font-size="11" font-weight="600" letter-spacing="0.5" fill="{COL["white"]}">{esc(hero_label)}</text>')
    out.append(f'<text x="116" y="{hy+82}" font-family="Inter" font-size="20" font-weight="700" fill="{COL["white"]}">{esc(title)}</text>')
    out.append(f'<text x="32" y="{hy+126}" font-family="Inter" font-size="14" fill="{COL["white"]}" fill-opacity="0.85">{esc(desc)}</text>')
    out.append(f'<text x="32" y="{hy+158}" font-family="Inter" font-size="12" fill="{COL["white"]}" fill-opacity="0.7">⏰ 2 godziny temu</text>')
    # Action card
    ay = y0 + 310
    out.append(f'<text x="20" y="{ay}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">REAKCJE</text>')
    ay += 16
    out.append(f'<rect x="16" y="{ay}" width="{W-32}" height="160" rx="10" fill="{COL["white"]}"/>')
    actions = [("✓", "Potwierdzam — widzę", "23"), ("✗", "Nie ma już", "2"), ("📞", "Zadzwoń do zgłaszającego", "")]
    for i,(emoji,tt,n) in enumerate(actions):
        ry = ay + i*54
        out.append(f'<text x="32" y="{ry+34}" font-family="Inter" font-size="18">{emoji}</text>')
        out.append(f'<text x="72" y="{ry+34}" font-family="Inter" font-size="16" fill="{COL["primary"]}">{esc(tt)}</text>')
        if n:
            out.append(f'<text x="{W-32}" y="{ry+34}" text-anchor="end" font-family="Inter" font-size="14" font-weight="600" fill="{COL["label2"]}">{n}</text>')
        if i < 2:
            out.append(f'<line x1="72" y1="{ry+54}" x2="{W-16}" y2="{ry+54}" stroke="{COL["sep"]}" stroke-width="0.5"/>')
    return "\n".join(out)

def body_stats(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Statystyki</text>')
    # Segmented control
    sy = y0 + 100
    out.append(f'<rect x="16" y="{sy}" width="{W-32}" height="36" rx="10" fill="{COL["sep"]}" fill-opacity="0.5"/>')
    seg = ["Dzień", "Tydzień", "Miesiąc"]
    for i,s in enumerate(seg):
        x = 16 + i*(W-32)/3
        if i == 1:
            out.append(f'<rect x="{x+4}" y="{sy+4}" width="{(W-40)/3}" height="28" rx="8" fill="{COL["white"]}"/>')
            out.append(f'<text x="{x+(W-32)/6}" y="{sy+23}" text-anchor="middle" font-family="Inter" font-size="13" font-weight="600" fill="{COL["primary"]}">{s}</text>')
        else:
            out.append(f'<text x="{x+(W-32)/6}" y="{sy+23}" text-anchor="middle" font-family="Inter" font-size="13" fill="{COL["label2"]}">{s}</text>')
    # Bars
    by = y0 + 180
    out.append(f'<rect x="16" y="{by}" width="{W-32}" height="220" rx="16" fill="{COL["white"]}"/>')
    out.append(f'<text x="32" y="{by+30}" font-family="Inter" font-size="14" font-weight="600" fill="{COL["primary"]}">Twoje zgłoszenia</text>')
    days = [("Pon", 2), ("Wt", 1), ("Śr", 3), ("Czw", 0), ("Pt", 1), ("Sob", 1), ("Nd", 0)]
    bx = 36
    for d, n in days:
        h = max(8, n*30)
        c = COL["voltMint"] if n > 0 else COL["sep"]
        out.append(f'<rect x="{bx}" y="{by+160-h}" width="32" height="{h}" rx="6" fill="{c}"/>')
        out.append(f'<text x="{bx+16}" y="{by+185}" text-anchor="middle" font-family="Inter" font-size="11" fill="{COL["label2"]}">{d}</text>')
        bx += 46
    # Stats grid
    sy = y0 + 420
    metrics = [("8", "Wszystkich"), ("34", "Potwierdzeń"), ("+104", "Reputacji")]
    for i,(v,l) in enumerate(metrics):
        x = 16 + i*(W-32)/3 + 4
        w = (W-48)/3
        out.append(f'<rect x="{x}" y="{sy}" width="{w}" height="80" rx="16" fill="{COL["white"]}"/>')
        out.append(f'<text x="{x+w/2}" y="{sy+38}" text-anchor="middle" font-family="Inter" font-size="22" font-weight="700" fill="{COL["primary"]}">{v}</text>')
        out.append(f'<text x="{x+w/2}" y="{sy+62}" text-anchor="middle" font-family="Inter" font-size="11" fill="{COL["label2"]}">{l}</text>')
    return "\n".join(out)

def body_referral(y0):
    out = []
    out.append(f'<text x="20" y="{y0+62}" font-family="Inter" font-size="34" font-weight="700" letter-spacing="-0.5" fill="{COL["primary"]}">Poleć znajomym</text>')
    out.append(f'<text x="20" y="{y0+92}" font-family="Inter" font-size="14" fill="{COL["label2"]}">Zaproś bliskich i dostań 50 pkt</text>')
    # Code card
    cy = y0 + 140
    out.append(f'<rect x="16" y="{cy}" width="{W-32}" height="180" rx="20" fill="{COL["mint"]}" fill-opacity="0.85"/>')
    out.append(f'<text x="{W/2}" y="{cy+44}" text-anchor="middle" font-family="Inter" font-size="12" font-weight="600" letter-spacing="2" fill="{COL["primary"]}">TWÓJ KOD</text>')
    out.append(f'<text x="{W/2}" y="{cy+106}" text-anchor="middle" font-family="Inter" font-size="48" font-weight="700" letter-spacing="6" fill="{COL["primary"]}">{USER["ref_code"]}</text>')
    out.append(f'<text x="{W/2}" y="{cy+140}" text-anchor="middle" font-family="Inter" font-size="12" fill="{COL["primary"]}" fill-opacity="0.7">besafe.org.pl/?ref={USER["ref_code"]}</text>')
    out.append(f'<rect x="{W/2-60}" y="{cy+150}" width="120" height="20" rx="10" fill="{COL["primary"]}"/>')
    out.append(f'<text x="{W/2}" y="{cy+164}" text-anchor="middle" font-family="Inter" font-size="11" font-weight="600" fill="{COL["white"]}">Kopiuj link</text>')
    # CTA
    out.append(f'<rect x="20" y="{y0+360}" width="{W-40}" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{W/2}" y="{y0+396}" text-anchor="middle" font-family="Inter" font-size="16" font-weight="600" fill="{COL["white"]}">📤 Udostępnij kod</text>')
    out.append(f'<text x="{W/2}" y="{y0+440}" text-anchor="middle" font-family="Inter" font-size="13" fill="{COL["label2"]}">Zaprosiłeś już <tspan font-weight="700" fill="{COL["primary"]}">0 osób</tspan></text>')
    return "\n".join(out)

# ── MASTER BUILDER ─────────────────────────────────────────────────────────

def make_frame(name, section, kind, label, dart_path, x_off, y_off):
    """Render a single frame at given (x_off, y_off) offset."""
    out = []
    out.append(f'<g class="frame" data-name="{name}" data-section="{section}" data-kind="{kind}" data-dart="{dart_path}" transform="translate({x_off},{y_off})">')
    # Clip group inside viewport
    clip_id = f"clip_{name}"
    out.append(f'<defs><clipPath id="{clip_id}"><rect x="0" y="0" width="{W}" height="{H}" rx="40"/></clipPath></defs>')
    out.append(f'<g clip-path="url(#{clip_id})">')
    # Background
    out.append(f'<rect x="0" y="0" width="{W}" height="{H}" rx="40" fill="{COL["grouped"]}"/>')
    # Status bar
    out.append(status_bar(0))

    body_y = 44
    # Render per kind
    if kind == "home":
        out.append(body_home(body_y))
    elif kind == "home_kids":
        out.append(body_home(body_y))  # similar layout
    elif kind == "home_senior":
        out.append(body_home(body_y))
    elif kind == "splash":
        out.append(body_onboarding(body_y))
    elif kind == "picker":
        out.append(body_picker(body_y))
    elif kind == "form":
        if "login" in name:
            out.append(body_login(body_y))
        elif "forgot" in name:
            out.append(body_form(body_y, "Zapomniałeś hasła?", "Wyślemy link na email.", [("Email", USER["email"])], "Wyślij link"))
        elif "alert_create" in name:
            out.append(body_form(body_y, "Zgłoś alert", "Co się dzieje w okolicy?", [("Tytuł", "Bójka przed dworcem"), ("Kategoria", "aggression"), ("Promień", "500 m")], "Wyślij zgłoszenie"))
        elif "escort" in name:
            out.append(body_form(body_y, "Eskorta", "Powiadom bliskich o podróży", [("Cel", "ul. Główna 14, Września"), ("Obserwator", "Marcin"), ("ETA", "20 min")], "Rozpocznij eskortę"))
        elif "fake_call_setup" in name:
            out.append(body_form(body_y, "Fałszywy telefon", "Awaryjna wymówka — uderzy za:", [("Kontakt", "Mama"), ("Opóźnienie", "10 sekund")], "Zaplanuj rozmowę"))
        else:
            out.append(body_form(body_y, label, "", [("Pole", "wartość")], "Zapisz"))
    elif kind == "map":
        out.append(body_map(body_y))
    elif kind == "list_groups":
        out.append(body_list_groups(body_y))
    elif kind == "list_members":
        out.append(body_list_members(body_y))
    elif kind == "chat":
        out.append(body_chat(body_y))
    elif kind == "sos":
        mode = "kids" if "kids" in name else ("senior" if "senior" in name else "normal")
        out.append(body_sos(body_y, mode))
    elif kind == "profile_self":
        out.append(body_profile_self(body_y))
    elif kind == "profile_member":
        out.append(body_profile_self(body_y))  # similar
    elif kind == "profile_child":
        out.append(body_profile_self(body_y))
    elif kind == "list_alerts":
        out.append(body_alerts_list(body_y))
    elif kind == "list_ranking":
        out.append(body_ranking(body_y))
    elif kind == "list_badges":
        out.append(body_badges(body_y))
    elif kind == "list_settings":
        out.append(body_settings(body_y))
    elif kind == "list_perms":
        items = [("📍", "Lokalizacja", "Zawsze"), ("📸", "Kamera", "Wł."), ("🎤", "Mikrofon", "Wył."), ("🔔", "Powiadomienia", "Wł."), ("🔐", "Biometria", "Wł."), ("📊", "Sensory", "Wł.")]
        out.append(body_simple_list(body_y, "Uprawnienia", items))
    elif kind == "list_events":
        items = [("🩺", "Wizyta lekarska Heluss", "jutro 14:00"), ("⚽", "Trening Justyna", "śr 16:00"), ("🎂", "Urodziny Marcina", "12 maja")]
        out.append(body_simple_list(body_y, "Planner", items))
    elif kind == "list_routes":
        items = [("🏫", "Dom — SP1", "Heluss · 1.2 km"), ("⚽", "Dom — Orlik", "Justyna · 800 m"), ("👵", "Szkoła — Babcia", "Heluss · 2 km"), ("🏠", "Dom — Przedszkole", "—")]
        out.append(body_simple_list(body_y, "Bezpieczne trasy", items))
    elif kind == "list_history":
        items = [("🏠", "Dom", "07:45 · 100%"), ("🏫", "Szkoła SP1", "08:12 · 98%"), ("⚽", "Orlik", "15:30 · 87%"), ("🛒", "Biedronka", "16:15 · 78%"), ("🏠", "Dom", "16:48 · 72%")]
        out.append(body_simple_list(body_y, "Historia · Heluss", items))
    elif kind == "list_simple":
        items = []
        if "guide" in name:
            items = [("🚨", "Numery alarmowe", "112, 998, 999..."), ("❤️", "Pierwsza pomoc RKO", "Krok po kroku"), ("🏠", "Bezpieczeństwo w domu", "Pożar, zalanie, włamanie"), ("⛈", "Burza i blackout", "Co robić gdy brak prądu"), ("🚪", "Drzwi, okna, klucze", "Ochrona mieszkania")]
        elif "emergency" in name:
            items = [("🚨", "112", "Numer alarmowy"), ("👮", "997", "Policja"), ("🚒", "998", "Straż pożarna"), ("🚑", "999", "Pogotowie"), ("⛰", "601 100 300", "GOPR")]
        elif "cyber" in name:
            items = [("🆔", "mObywatel — zastrzeż PESEL", "obywatel.gov.pl"), ("🔐", "Have I Been Pwned", "haveibeenpwned.com"), ("⚠️", "CERT.pl", "Zgłoś incydent"), ("📱", "Zgłoś SMS spam", "wyślij na 8080")]
        elif "mental" in name:
            items = [("📞", "116 123", "Telefon zaufania dorośli"), ("👶", "116 111", "Telefon zaufania dzieci"), ("🚨", "112", "Sytuacja krytyczna"), ("💬", "psycholodzy.pl", "Online pomoc")]
        elif "news" in name:
            items = [("📢", "Nowy alert w Twojej okolicy", "Pożar przy ul. Słonecznej"), ("🛡", "Tygodniowe podsumowanie", "8 alertów rozwiązanych"), ("🎉", "Twoja odznaka: Strażnik!", "Otrzymałeś 50 pkt")]
        elif "parental" in name:
            items = [("👨‍👩‍👧", "Google Family Link", "Czas ekranowy"), ("🍎", "Apple Screen Time", "Limity na iOS"), ("🛡", "Qustodio", "Filtr treści"), ("🐺", "Bark", "Monitor mediów społ."), ("📚", "NASK · dyzurnet.pl", "Zgłoś treści")]
        elif "pets" in name:
            items = [("🐕", "Burek", "Dom · 12 lat"), ("🐈", "Mila", "Dom · 4 lata"), ("➕", "Dodaj zwierzaka", "")]
        elif "legal" in name:
            items = [("📜", "Polityka prywatności", "Ostatnia aktualizacja: 05/2026"), ("📋", "Regulamin", "Wersja 1.2"), ("ℹ️", "O aplikacji", "be:Safe v98"), ("📧", "Kontakt", "kontakt@besafe.org.pl")]
        title = label
        out.append(body_simple_list(body_y, title, items))
    elif kind == "detail":
        if "alert_detail" in name:
            out.append(body_detail(body_y, "Bójka przed dworcem", "Grupa 3-4 młodych mężczyzn awanturuje się przy wejściu od strony peronu. Wezwano patrol.", COL["coral"], "ALERT · AGRESJA"))
        elif "ping_response" in name:
            out.append(body_detail(body_y, "Marcin pyta: Gdzie jesteś?", "Wyślij swoją lokalizację albo odpowiedz wiadomością.", COL["navy"], "PING · 5 MIN TEMU"))
        elif "fake_call_incoming" in name:
            # Special: fullscreen incoming call
            out.append(f'<rect x="0" y="44" width="{W}" height="{H-44}" fill="{COL["primary"]}"/>')
            out.append(f'<text x="{W/2}" y="160" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["white"]}" fill-opacity="0.7">Połączenie przychodzące</text>')
            out.append(f'<circle cx="{W/2}" cy="280" r="70" fill="{COL["mint"]}" fill-opacity="0.6"/>')
            out.append(f'<text x="{W/2}" y="295" text-anchor="middle" font-size="56">📞</text>')
            out.append(f'<text x="{W/2}" y="400" text-anchor="middle" font-family="Inter" font-size="32" font-weight="300" fill="{COL["white"]}">Mama</text>')
            out.append(f'<text x="{W/2}" y="430" text-anchor="middle" font-family="Inter" font-size="14" fill="{COL["white"]}" fill-opacity="0.6">Połączenie głosowe</text>')
            # Accept / Decline
            out.append(f'<circle cx="{W/2-70}" cy="700" r="36" fill="{COL["red"]}"/>')
            out.append(f'<text x="{W/2-70}" y="710" text-anchor="middle" font-size="22" fill="{COL["white"]}">📵</text>')
            out.append(f'<circle cx="{W/2+70}" cy="700" r="36" fill="{COL["green"]}"/>')
            out.append(f'<text x="{W/2+70}" y="710" text-anchor="middle" font-size="22" fill="{COL["white"]}">📞</text>')
        else:
            out.append(body_detail(body_y, label, "Szczegóły zgłoszenia.", COL["navy"]))
    elif kind == "stats":
        out.append(body_stats(body_y))
    elif kind == "referral":
        out.append(body_referral(body_y))
    elif kind == "draw":
        out.append(body_map(body_y))  # map with draw mode
        out.append(f'<text x="20" y="{body_y+30}" font-family="Inter" font-size="16" font-weight="600" fill="{COL["primary"]}">{esc(label)}</text>')
    else:
        out.append(f'<text x="20" y="{body_y+120}" font-family="Inter" font-size="20" fill="{COL["label2"]}">{esc(label)}</text>')

    # Dock — skip on: onboarding, login, fake_call_incoming, sos kids/senior full
    skip_dock = kind in ("splash",) or "fake_call_incoming" in name or "login" in name or "forgot" in name
    if not skip_dock:
        out.append(dock(H-86))

    out.append('</g>')
    # Frame border + label
    out.append(f'<rect x="0" y="0" width="{W}" height="{H}" rx="40" fill="none" stroke="{COL["outline"]}" stroke-width="1"/>')
    out.append(f'<text x="0" y="{H+24}" font-family="Inter" font-size="11" font-weight="600" fill="{COL["primary"]}">{esc(name)}</text>')
    out.append(f'<text x="0" y="{H+40}" font-family="Inter" font-size="10" fill="{COL["label2"]}">{esc(label)}</text>')
    out.append('</g>')
    return "\n".join(out)


def build_master():
    rows = (len(SCREENS) + COLS - 1) // COLS
    total_w = PAD*2 + COLS*W + (COLS-1)*GAP
    total_h = PAD*2 + rows*(H+60) + (rows-1)*GAP + 120  # +header

    svg = []
    svg.append(f'<?xml version="1.0" encoding="UTF-8"?>')
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_w}" height="{total_h}" viewBox="0 0 {total_w} {total_h}">')
    # Page bg
    svg.append(f'<rect width="100%" height="100%" fill="#F8F8FA"/>')
    # Header
    svg.append(f'<text x="{PAD}" y="{PAD-20}" font-family="Inter" font-size="42" font-weight="700" fill="{COL["primary"]}">be:Safe — All Screens v98</text>')
    svg.append(f'<text x="{PAD}" y="{PAD+12}" font-family="Inter" font-size="16" font-weight="400" fill="{COL["label2"]}">44 frames · Serenity Guard + iOS-style + voltMint accent · realne dane m3n3s · viewport 390×844</text>')

    y_offset = PAD + 80
    for i, (name, section, kind, label, dart) in enumerate(SCREENS):
        col = i % COLS
        row = i // COLS
        x = PAD + col*(W+GAP)
        y = y_offset + row*(H+60+GAP)
        svg.append(make_frame(name, section, kind, label, dart, x, y))

    svg.append('</svg>')
    return "\n".join(svg)


def build_individual(name, section, kind, label, dart_path):
    svg = []
    svg.append(f'<?xml version="1.0" encoding="UTF-8"?>')
    svg.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
    # Render at 0,0 — pass big y so label/border still anchored correctly.
    # We need to wrap make_frame contents directly for clean output:
    body = make_frame(name, section, kind, label, dart_path, 0, 0)
    # Strip the outer translate
    body = body.replace(f' transform="translate(0,0)"', '')
    svg.append(body)
    svg.append('</svg>')
    return "\n".join(svg)


def main():
    out_dir = Path("/home/ooxo/alert/design/figma-export-v98")
    out_dir.mkdir(exist_ok=True)
    indiv_dir = out_dir / "individual"
    indiv_dir.mkdir(exist_ok=True)

    # Master combined
    master = build_master()
    (out_dir / "besafe_v98_all.svg").write_text(master, encoding="utf-8")
    print(f"✓ Master SVG: {out_dir / 'besafe_v98_all.svg'} ({len(master)//1024} KB)")

    # Individual frames
    for (name, section, kind, label, dart) in SCREENS:
        svg = build_individual(name, section, kind, label, dart)
        (indiv_dir / f"{name}.svg").write_text(svg, encoding="utf-8")
    print(f"✓ Individual: {len(SCREENS)} files in {indiv_dir}")

    # index.html
    html_doc = ['<!DOCTYPE html><html><head><meta charset="utf-8">',
                '<title>be:Safe v98 — Figma Export</title>',
                '<style>body{font-family:Inter,system-ui;background:#0A0E14;color:#fff;padding:20px}',
                'h1{font-weight:300}h2{margin-top:40px;color:#9DF4CB}',
                '.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:24px}',
                '.card{background:#131820;border-radius:16px;padding:12px;text-align:center}',
                '.card object{display:block;width:100%;border-radius:8px;background:#F2F2F7;aspect-ratio:390/844}',
                '.card p{margin:8px 0 0;font-size:12px;color:#9CA3AF}.card strong{color:#fff;font-size:13px;display:block;margin-top:6px}</style></head><body>',
                '<h1>be:Safe — All Screens v98</h1>',
                f'<p style="color:#9CA3AF">44 frames z realnymi danymi konta meneswczesny@gmail.com (m3n3s). Wygenerowane {Path(__file__).name}.</p>',
                '<h2>📱 Wszystkie ekrany</h2>',
                '<div class="grid">']
    for (name, _, _, label, _) in SCREENS:
        html_doc.append(f'<div class="card"><object data="individual/{name}.svg" type="image/svg+xml"></object><strong>{esc(label)}</strong><p>{esc(name)}</p></div>')
    html_doc.append('</div></body></html>')
    (out_dir / "index.html").write_text("\n".join(html_doc), encoding="utf-8")
    print(f"✓ Preview: {out_dir / 'index.html'}")

if __name__ == "__main__":
    main()
