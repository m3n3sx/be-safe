#!/usr/bin/env python3
"""Generate be:Safe Figma-importable SVG with all 44 named frames.

Output: besafe_frames.svg — single SVG with 44 frames in 7-col grid.
Each frame is a top-level <g> with id matching screen name. Figma File→Import
imports SVG groups as Frames with the group's id as Frame name.

Also produces:
- besafe_frames_individual/ — one SVG per screen (alternative import)
- besafe_frames_index.html — preview in browser
"""
import os
from pathlib import Path

OUT = Path(__file__).parent
INDIV = OUT / "besafe_frames_individual"
INDIV.mkdir(exist_ok=True)

# Viewport iPhone 14 Pro / common Android: 390x844
W, H = 390, 844
# Grid: 7 cols × 7 rows (49 slots, 44 used)
COLS = 7
GAP = 80
PAD = 80

# Serenity Guard palette (b51 / v83 iOS tokens)
COL = {
    "navy":     "#1A2027",   # primary text + primaryContainer
    "mint":     "#9DF4CB",   # accent/glow
    "aqua":     "#9EEBEC",   # secondary accent
    "coral":    "#FF7A7A",   # SOS/destructive
    "grouped":  "#F2F2F7",   # iOS groupedBackground
    "white":    "#FFFFFF",
    "sep":      "#C6C6C8",
    "label2":   "#8E8E93",   # secondaryLabel
    "outline":  "#E5E5EA",
}

# REAL DATA — pulled live from prod DB (alertmap @ 16.192.31.100) for user
# meneswczesny@gmail.com (id 0a397992-115e-465e-b409-429b31690210)
USER = {
    "username":   "m3n3s",
    "display":    "Piotr Menes",
    "email":      "meneswczesny@gmail.com",
    "reputation": 104,
    "initial":    "P",
    "app_mode":   "normal",
    "joined":     "30 kwietnia 2026",
}

# 6 groups owned by m3n3s, ordered as in DB
GROUPS = [
    {"name": "Kasty przychlasty",   "invite": "64410260", "members": 2},
    {"name": "Grupa1",              "invite": "BB400AB5", "members": 7},
    {"name": "Grupa",               "invite": "5E202124", "members": 2},
    {"name": "grupa",               "invite": "796D3499", "members": 2},
    {"name": "Rodzina Testowa E2E", "invite": "E2ETEST",  "members": 4},
    {"name": "Babcia Solo",         "invite": "BABCIA1",  "members": 2},
]

# Real members from Grupa1 (the most populated group)
MEMBERS_GRUPA1 = [
    {"name": "piotr",                  "role": "parent", "battery": 100, "is_child": False, "online": True},
    {"name": "Marcin",                 "role": "parent", "battery": 100, "is_child": False, "online": True},
    {"name": "m3n3s",                  "role": "parent", "battery": 73,  "is_child": True,  "online": True},
    {"name": "Michael Skweres (Hiki)", "role": "parent", "battery": 46,  "is_child": False, "online": False},
    {"name": "Marek Kołodziejczyk",    "role": "parent", "battery": 85,  "is_child": False, "online": True},
    {"name": "Justyna Rewers",         "role": "child",  "battery": 32,  "is_child": True,  "online": False},
    {"name": "Heluss Menelek",         "role": "child",  "battery": 98,  "is_child": True,  "online": True},
]

# Last 8 alerts authored by m3n3s
ALERTS = [
    {"title": "Agresywna grupa pod ratuszem", "category": "aggression",  "status": "expired", "date": "23.05.2026"},
    {"title": "Krzyki w parku po 22:00",      "category": "aggression",  "status": "expired", "date": "23.05.2026"},
    {"title": "Bójka przed dworcem",          "category": "aggression",  "status": "expired", "date": "23.05.2026"},
    {"title": "Zatrzymanie przy ratuszu",     "category": "police",      "status": "expired", "date": "23.05.2026"},
    {"title": "Patrol policji na rynku",      "category": "police",      "status": "expired", "date": "23.05.2026"},
    {"title": "Bezpański pies w parku",       "category": "animal",      "status": "expired", "date": "23.05.2026"},
    {"title": "Padający słup energetyczny",   "category": "other",       "status": "expired", "date": "23.05.2026"},
    {"title": "Auto bez przepisów przy SP1",  "category": "school_zone", "status": "expired", "date": "23.05.2026"},
]

# Top reputation leaderboard
RANKING = [
    {"name": "m3n3s",       "rep": 104, "you": True},
    {"name": "Test",        "rep": 100},
    {"name": "Dupowaty",    "rep": 100},
    {"name": "Tadeusz",     "rep": 100},
    {"name": "AlertBot",    "rep": 100},
    {"name": "DemoUser",    "rep": 100},
    {"name": "Gość51BB",    "rep": 100},
    {"name": "Piotr Menes", "rep": 100},
]

# All 44 screens grouped by section. (frame_name, section, kind, label_pl, dart_path)
SCREENS = [
    # AUTH / ONBOARDING (5)
    ("01_onboarding",          "Onboarding",  "splash",   "Onboarding (5 stron)",      "onboarding/onboarding_screen.dart"),
    ("02_mode_picker",         "Onboarding",  "picker",   "Wybór trybu (Kids/Senior/Normal)", "mode/mode_picker_screen.dart"),
    ("03_login",               "Auth",        "form",     "Logowanie",                 "auth/login_screen.dart"),
    ("04_forgot_password",     "Auth",        "form",     "Reset hasła",               "auth/forgot_password_screen.dart"),

    # HOME (3 modes)
    ("10_home_normal",         "Home",        "home",     "Home — Normal",             "home/home_screen.dart"),
    ("11_home_kids",           "Home",        "home",     "Home — Kids",               "home/home_kids_screen.dart"),
    ("12_home_senior",         "Home",        "home",     "Home — Senior",             "home/home_senior_screen.dart"),

    # MAP
    ("20_map",                 "Mapa",        "map",      "Mapa alertów",              "map/map_screen.dart"),

    # ALERTS (4)
    ("21_alert_detail",        "Alerty",      "detail",   "Szczegóły alertu",          "alerts/alert_detail_screen.dart"),
    ("22_alert_create",        "Alerty",      "form",     "Zgłoś alert",               "alerts/create_alert_screen.dart"),
    ("23_alerts_my",           "Alerty",      "list",     "Moje zgłoszenia",           "alerts/my_alerts_screen.dart"),
    ("24_alerts_stats",        "Alerty",      "stats",    "Statystyki",                "alerts/stats_screen.dart"),

    # FAMILY (12)
    ("30_family",              "Rodzina",     "list",     "Rodzina",                   "family/family_screen.dart"),
    ("31_family_group",        "Rodzina",     "list",     "Grupa1 — członkowie",       "family/family_group_screen.dart"),
    ("32_family_chat",         "Rodzina",     "chat",     "Czat rodzinny",             "family/family_chat_screen.dart"),
    ("33_family_planner",      "Rodzina",     "list",     "Planner",                   "family/family_planner_screen.dart"),
    ("34_family_sos",          "Rodzina",     "sos",      "Family SOS",                "family/family_sos_screen.dart"),
    ("35_member_profile",      "Rodzina",     "profile",  "Profil członka",            "family/member_profile_screen.dart"),
    ("36_child_profile",       "Rodzina",     "profile",  "Profil dziecka",            "family/child_profile_screen.dart"),
    ("37_safe_routes",         "Rodzina",     "list",     "Bezpieczne trasy",          "family/safe_routes_screen.dart"),
    ("38_draw_safe_route",     "Rodzina",     "map",      "Rysuj trasę",               "family/draw_safe_route_screen.dart"),
    ("39_add_geofence",        "Rodzina",     "map",      "Dodaj strefę",              "family/add_geofence_screen.dart"),
    ("40_location_history",    "Rodzina",     "list",     "Historia lokalizacji",      "family/location_history_screen.dart"),
    ("41_ping_response",       "Rodzina",     "detail",   "Odpowiedź na ping",         "family/ping_response_screen.dart"),

    # SOS (3 modes)
    ("50_sos_normal",          "SOS",         "sos",      "SOS — Normal",              "sos/sos_screen.dart"),
    ("51_sos_kids",            "SOS",         "sos",      "SOS — Kids",                "sos/sos_kids_screen.dart"),
    ("52_sos_senior",          "SOS",         "sos",      "SOS — Senior",              "sos/sos_senior_screen.dart"),

    # PROFILE (4)
    ("60_profile",             "Profil",      "list",     "Profil",                    "profile/profile_screen.dart"),
    ("61_badges",              "Profil",      "list",     "Odznaki",                   "profile/badges_screen.dart"),
    ("62_ranking",             "Profil",      "list",     "Ranking",                   "profile/ranking_screen.dart"),
    ("63_referral",            "Profil",      "list",     "Polecaj znajomym",          "profile/referral_screen.dart"),

    # SETTINGS / SYSTEM (3)
    ("70_settings",            "Ustawienia",  "list",     "Ustawienia",                "settings/settings_screen.dart"),
    ("71_permissions",         "Ustawienia",  "list",     "Uprawnienia",               "permissions/permissions_screen.dart"),
    ("72_parental_controls",   "Ustawienia",  "list",     "Kontrola rodzicielska",     "parental_controls/parental_controls_screen.dart"),

    # SAFETY / EMERGENCY (6)
    ("80_safety_guide",        "Bezpieczeństwo", "list",  "Poradnik 12 sekcji",        "safety/safety_guide_screen.dart"),
    ("81_emergency_numbers",   "Bezpieczeństwo", "list",  "Numery alarmowe",           "emergency/emergency_numbers_screen.dart"),
    ("82_cyber_safety",        "Bezpieczeństwo", "list",  "Cyber-bezpieczeństwo",      "cyber_safety/cyber_safety_screen.dart"),
    ("83_mental_health_sos",   "Bezpieczeństwo", "sos",   "Mental Health SOS",         "mental_health/mental_health_sos_screen.dart"),

    # COMMUNITY / NEWS
    ("90_news",                "Społeczność", "list",     "Aktualności",               "community/news_screen.dart"),

    # EXTRA FEATURES (4)
    ("a0_escort",              "Funkcje",     "form",     "Eskorta (Follow Me)",       "escort/escort_screen.dart"),
    ("a1_fake_call_setup",     "Funkcje",     "form",     "Fake Call — setup",         "fake_call/fake_call_setup_screen.dart"),
    ("a2_fake_call_incoming",  "Funkcje",     "splash",   "Fake Call — przychodzące",  "fake_call/fake_call_incoming_screen.dart"),
    ("a3_pets",                "Funkcje",     "list",     "Zwierzaki (Pet Mode)",      "pets/pets_screen.dart"),

    # LEGAL
    ("b0_legal",               "Inne",        "list",     "Regulamin / Polityka",      "legal/legal_screen.dart"),
]

assert len(SCREENS) == 44, f"Expected 44 screens, got {len(SCREENS)}"


def make_frame_svg(name, section, kind, label, dart_path, x_offset=0, y_offset=0, embed=False):
    """Build a single frame as SVG <g> at given offset.

    If embed=True returns inner content for grid SVG; else returns full SVG file.
    """
    inner = []
    # Background
    inner.append(f'<rect x="0" y="0" width="{W}" height="{H}" fill="{COL["grouped"]}" />')

    # Status bar (44h)
    inner.append(f'<rect x="0" y="0" width="{W}" height="44" fill="{COL["grouped"]}" />')
    inner.append(f'<text x="24" y="28" font-family="SF Pro, Inter, sans-serif" font-size="14" font-weight="600" fill="{COL["navy"]}">9:41</text>')
    inner.append(f'<g transform="translate({W-80},14)"><circle cx="6" cy="6" r="2" fill="{COL["navy"]}"/><rect x="14" y="2" width="22" height="10" rx="3" fill="none" stroke="{COL["navy"]}" stroke-width="1.2"/><rect x="16" y="4" width="14" height="6" rx="1" fill="{COL["navy"]}"/></g>')

    # Top app bar (88h) — title + back
    bar_y = 44
    inner.append(f'<rect x="0" y="{bar_y}" width="{W}" height="56" fill="{COL["grouped"]}" />')
    if kind not in ("home", "splash"):
        # Back chevron
        inner.append(f'<text x="20" y="{bar_y+34}" font-family="SF Pro" font-size="22" fill="{COL["navy"]}">‹</text>')
    inner.append(f'<text x="{W//2}" y="{bar_y+34}" text-anchor="middle" font-family="Inter, sans-serif" font-size="17" font-weight="600" fill="{COL["navy"]}">{label}</text>')

    # Body area (y=100..780, leaving 64 for dock)
    body_y = 110
    body_h = H - body_y - 76   # 76 = dock bar height + safe area

    # Content per kind
    if kind == "home":
        # Greeting + large title (use real user name on NORMAL home)
        if name == "30_family":
            title_text = "Rodzina"
            sub_text = f'{len(GROUPS)} grup · {sum(g["members"] for g in GROUPS)} osób'
        else:
            title_text = f'Cześć, {USER["display"].split()[0]}'
            sub_text = "Wszystko w porządku w Twojej okolicy"
        inner.append(f'<text x="20" y="{body_y+30}" font-family="Inter" font-size="34" font-weight="700" fill="{COL["navy"]}">{title_text}</text>')
        # Hero card (mint glow circle)
        hy = body_y + 60
        inner.append(f'<rect x="16" y="{hy}" width="{W-32}" height="180" rx="20" fill="{COL["white"]}" />')
        inner.append(f'<circle cx="{W-70}" cy="{hy+60}" r="80" fill="{COL["mint"]}" opacity="0.35"/>')
        inner.append(f'<text x="32" y="{hy+38}" font-family="Inter" font-size="13" font-weight="600" fill="{COL["label2"]}">STATUS OKOLICY</text>')
        inner.append(f'<text x="32" y="{hy+76}" font-family="Inter" font-size="22" font-weight="700" fill="{COL["navy"]}">Wszystko w porządku</text>')
        inner.append(f'<text x="32" y="{hy+102}" font-family="Inter" font-size="15" font-weight="400" fill="{COL["label2"]}">{sub_text}</text>')
        # 2 stat cards — real m3n3s data
        sy = hy + 200
        if name == "30_family":
            stats = [(str(len(GROUPS)), "GRUPY"), (str(sum(g["members"] for g in GROUPS)), "CZŁONKOWIE")]
        else:
            stats = [(str(USER["reputation"]), "REPUTACJA"), (str(len(GROUPS)), "RODZINA")]
        for i, (val, lbl) in enumerate(stats):
            cx = 16 + i*(W//2 - 8)
            inner.append(f'<rect x="{cx}" y="{sy}" width="{W//2 - 24}" height="100" rx="20" fill="{COL["white"]}"/>')
            inner.append(f'<text x="{cx+16}" y="{sy+34}" font-family="Inter" font-size="34" font-weight="700" fill="{COL["navy"]}">{val}</text>')
            inner.append(f'<text x="{cx+16}" y="{sy+62}" font-family="Inter" font-size="13" font-weight="600" fill="{COL["label2"]}">{lbl}</text>')
        # FAB
        fab_y = body_y + body_h - 80
        inner.append(f'<rect x="{W-130}" y="{fab_y}" width="110" height="46" rx="23" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W-75}" y="{fab_y+30}" text-anchor="middle" font-family="Inter" font-size="15" font-weight="600" fill="{COL["white"]}">+ Zgłoś</text>')

    elif kind == "splash":
        # Big glow + headline
        cx, cy = W//2, body_y + 200
        inner.append(f'<circle cx="{cx}" cy="{cy}" r="130" fill="{COL["mint"]}" opacity="0.4"/>')
        inner.append(f'<circle cx="{cx}" cy="{cy}" r="90" fill="{COL["aqua"]}" opacity="0.6"/>')
        inner.append(f'<text x="{W//2}" y="{cy+220}" text-anchor="middle" font-family="Inter" font-size="28" font-weight="300" fill="{COL["navy"]}">{label}</text>')
        inner.append(f'<text x="{W//2}" y="{cy+260}" text-anchor="middle" font-family="Inter" font-size="15" font-weight="400" fill="{COL["label2"]}">Lorem ipsum dolor sit amet</text>')
        # CTA pill
        py = body_y + body_h - 100
        inner.append(f'<rect x="24" y="{py}" width="{W-48}" height="56" rx="28" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W//2}" y="{py+35}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="600" fill="{COL["white"]}">Dalej</text>')

    elif kind == "form":
        # Form fields — real email for login frame
        fy = body_y + 30
        if name.startswith("03_login"):
            fields = [("Email", USER["email"]), ("Hasło", "••••••••")]
            cta = "Zaloguj się"
        elif name.startswith("04_forgot"):
            fields = [("Email", USER["email"]), ("", "")]
            cta = "Wyślij link"
        elif name.startswith("22_alert_create"):
            fields = [("Tytuł", "Bójka przed dworcem"), ("Kategoria", "Agresja")]
            cta = "Opublikuj alert"
        elif name.startswith("a0_escort"):
            fields = [("Cel podróży", "ul. Główna 14, Września"), ("Obserwator", "Marcin")]
            cta = "Rozpocznij eskortę"
        elif name.startswith("a1_fake_call"):
            fields = [("Imię dzwoniącego", "Mama"), ("Opóźnienie", "10 sekund")]
            cta = "Zaplanuj fałszywy telefon"
        else:
            fields = [("Email", USER["email"]), ("Hasło", "••••••••")]
            cta = "Zaloguj się"
        for i, (lbl, val) in enumerate(fields):
            if not lbl:
                continue
            inner.append(f'<rect x="16" y="{fy + i*84}" width="{W-32}" height="64" rx="14" fill="{COL["white"]}"/>')
            inner.append(f'<text x="32" y="{fy + i*84 + 26}" font-family="Inter" font-size="12" font-weight="500" fill="{COL["label2"]}">{lbl}</text>')
            inner.append(f'<text x="32" y="{fy + i*84 + 50}" font-family="Inter" font-size="17" fill="{COL["navy"]}">{val}</text>')
        # CTA
        cy_ = fy + 200
        inner.append(f'<rect x="16" y="{cy_}" width="{W-32}" height="52" rx="26" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W//2}" y="{cy_+33}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="600" fill="{COL["white"]}">{cta}</text>')

    elif kind == "picker":
        # 3 mode cards
        for i, (t, sub, gc) in enumerate([("Dla dziecka","KIDS — uproszczony",COL["coral"]),("Dla seniora","SENIOR — duże przyciski",COL["aqua"]),("Standardowy","NORMAL — pełna funkcjonalność",COL["mint"])]):
            cy_ = body_y + 30 + i*150
            inner.append(f'<rect x="16" y="{cy_}" width="{W-32}" height="130" rx="20" fill="{COL["white"]}"/>')
            inner.append(f'<circle cx="64" cy="{cy_+65}" r="36" fill="{gc}" opacity="0.5"/>')
            inner.append(f'<text x="120" y="{cy_+58}" font-family="Inter" font-size="20" font-weight="700" fill="{COL["navy"]}">{t}</text>')
            inner.append(f'<text x="120" y="{cy_+86}" font-family="Inter" font-size="13" fill="{COL["label2"]}">{sub}</text>')

    elif kind == "map":
        # Map placeholder + pins
        inner.append(f'<rect x="0" y="{body_y}" width="{W}" height="{body_h - 80}" fill="#E8ECEE"/>')
        for i, (px, py, c) in enumerate([(80, body_y+120, COL["coral"]), (220, body_y+200, COL["mint"]), (150, body_y+340, COL["aqua"])]):
            inner.append(f'<circle cx="{px}" cy="{py}" r="14" fill="{c}" stroke="{COL["white"]}" stroke-width="3"/>')
        # FAB
        inner.append(f'<rect x="{W-130}" y="{body_y + body_h - 130}" width="110" height="46" rx="23" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W-75}" y="{body_y + body_h - 100}" text-anchor="middle" font-family="Inter" font-size="15" font-weight="600" fill="{COL["white"]}">+ Zgłoś</text>')

    elif kind == "list":
        # Per-screen real data
        section_lbl = "SEKCJA"
        items = []  # (label, value, icon_color)
        if name == "23_alerts_my":
            section_lbl = "MOJE ZGŁOSZENIA"
            items = [(a["title"], a["status"], COL["coral"]) for a in ALERTS[:5]]
        elif name == "30_family":
            section_lbl = "GRUPY RODZINNE"
            items = [(g["name"], f'{g["members"]} osób · {g["invite"]}', COL["mint"]) for g in GROUPS]
        elif name == "31_family_group":
            section_lbl = "GRUPA1 — CZŁONKOWIE"
            items = [
                (m["name"], f'{m["role"]} · 🔋 {m["battery"]}% · {"Online" if m["online"] else "Offline"}', COL["coral"] if m["is_child"] else COL["mint"])
                for m in MEMBERS_GRUPA1
            ]
        elif name == "33_family_planner":
            section_lbl = "NADCHODZĄCE WYDARZENIA"
            items = [
                ("Wizyta u lekarza — Heluss",   "jutro 10:00", COL["aqua"]),
                ("Trening piłki — Justyna",    "śr 17:00",    COL["aqua"]),
                ("Spotkanie rodzinne",          "sob 15:00",    COL["aqua"]),
                ("Urodziny Marcina",            "29.05",        COL["mint"]),
                ("Wywiadówka — Justyna",        "02.06",        COL["mint"]),
            ]
        elif name == "37_safe_routes":
            section_lbl = "BEZPIECZNE TRASY"
            items = [
                ("Dom → Szkoła SP1",     "1,2 km · aktywna",  COL["mint"]),
                ("Dom → Boisko Orlik",   "800 m",             COL["mint"]),
                ("Szkoła → Babcia",      "2,1 km",            COL["aqua"]),
                ("Dom → Przedszkole",    "600 m",             COL["aqua"]),
            ]
        elif name == "40_location_history":
            section_lbl = "OSTATNIE 24H — HELUSS"
            items = [
                ("Dom · ul. Mickiewicza 7",   "06:45 — 07:30", COL["mint"]),
                ("Szkoła SP1",                "07:50 — 14:10", COL["mint"]),
                ("Boisko Orlik",              "14:30 — 16:00", COL["aqua"]),
                ("Sklep Biedronka",           "16:15 — 16:25", COL["aqua"]),
                ("Dom · ul. Mickiewicza 7",   "16:35 — teraz", COL["mint"]),
            ]
        elif name == "60_profile":
            section_lbl = "KONTO"
            items = [
                ("Dane konta",            USER["email"],          COL["mint"]),
                ("Promień powiadomień",   "2,5 km",                COL["mint"]),
                ("Tryb aplikacji",        "Standardowy",           COL["aqua"]),
                ("Odznaki",               "Zobacz wszystkie",      COL["mint"]),
                ("Polecaj znajomym",      f'kod: {USER["username"].upper()}', COL["aqua"]),
            ]
        elif name == "61_badges":
            section_lbl = "TWOJE ODZNAKI"
            items = [
                ("🥇 Pierwszy alert",      "zdobyte 30.04.2026",    COL["mint"]),
                ("👁 Czujne oko",          "10 potwierdzeń",        COL["mint"]),
                ("🛡 Strażnik okolicy",    "50 alertów",            COL["mint"]),
                ("👥 Lider rodziny",       "6 grup",                COL["aqua"]),
                ("⭐ Reputacja 100+",      f'{USER["reputation"]} pkt',  COL["coral"]),
            ]
        elif name == "62_ranking":
            section_lbl = "TOP UŻYTKOWNICY"
            items = [(f'{i+1}. {r["name"]}{" (Ty)" if r.get("you") else ""}', f'{r["rep"]} pkt', COL["coral"] if r.get("you") else COL["mint"]) for i, r in enumerate(RANKING[:5])]
        elif name == "63_referral":
            section_lbl = "POLECAJ ZNAJOMYM"
            items = [
                ("Twój kod",         USER["username"].upper(),   COL["mint"]),
                ("Polecenia",        "0 zarejestrowanych",        COL["aqua"]),
                ("Nagroda",          "+10 reputacji",             COL["mint"]),
                ("Skopiuj link",     "besafe.org.pl/?ref=M3N3S",  COL["aqua"]),
            ]
        elif name == "70_settings":
            section_lbl = "USTAWIENIA"
            items = [
                ("Powiadomienia",     "Włączone",       COL["mint"]),
                ("Język",             "Polski",         COL["aqua"]),
                ("Tryb aplikacji",    "Standardowy",    COL["aqua"]),
                ("Prywatność",        "Ghost Mode",     COL["mint"]),
                ("Wersja",            "v93",            COL["mint"]),
            ]
        elif name == "71_permissions":
            section_lbl = "UPRAWNIENIA"
            items = [
                ("📍 Lokalizacja",      "Włączone",      COL["mint"]),
                ("📷 Aparat",           "Włączone",      COL["mint"]),
                ("🎤 Mikrofon",         "Wyłączone",     COL["coral"]),
                ("🔔 Powiadomienia",    "Włączone",      COL["mint"]),
                ("👆 Biometria",        "Włączone",      COL["mint"]),
            ]
        elif name == "72_parental_controls":
            section_lbl = "KONTROLA RODZICIELSKA"
            items = [
                ("Google Family Link",  "Konfiguruj",    COL["mint"]),
                ("Apple Screen Time",   "Otwórz",        COL["mint"]),
                ("Qustodio",            "Pobierz",       COL["aqua"]),
                ("Bark",                "Pobierz",       COL["aqua"]),
                ("CERT.pl / NASK",      "Zgłoś treść",   COL["coral"]),
            ]
        elif name == "80_safety_guide":
            section_lbl = "PORADNIK"
            items = [
                ("Numery alarmowe",     "112, 997, 998", COL["coral"]),
                ("Pierwsza pomoc RKO",  "krok po kroku", COL["coral"]),
                ("Bezpieczeństwo w domu","8 zasad",       COL["mint"]),
                ("Burza i blackout",    "co robić",      COL["aqua"]),
                ("Oszustwa 'na wnuczka'", "rozpoznaj",     COL["coral"]),
            ]
        elif name == "81_emergency_numbers":
            section_lbl = "NUMERY ALARMOWE"
            items = [
                ("112", "Numer alarmowy",            COL["coral"]),
                ("997", "Policja",                   COL["coral"]),
                ("998", "Straż pożarna",             COL["coral"]),
                ("999", "Pogotowie ratunkowe",       COL["coral"]),
                ("601 100 100", "WOPR",              COL["aqua"]),
            ]
        elif name == "82_cyber_safety":
            section_lbl = "CYBER-BEZPIECZEŃSTWO"
            items = [
                ("mObywatel — zastrzeż PESEL", "rządowa apka", COL["mint"]),
                ("bezpiecznedane.gov.pl",      "sprawdź dane", COL["mint"]),
                ("Have I Been Pwned",          "wyciekły hasła", COL["coral"]),
                ("CERT.pl",                    "zgłoś incydent", COL["aqua"]),
                ("SMS 8080",                   "zgłoś oszustwo", COL["coral"]),
            ]
        elif name == "90_news":
            section_lbl = "AKTUALNOŚCI"
            items = [
                ("Nowy radar fotograficzny",     "10 min temu",    COL["coral"]),
                ("Utrudnienia na ul. Wrocławskiej","godzinę temu", COL["aqua"]),
                ("Akcja sprzątania parku",        "wczoraj",        COL["mint"]),
                ("Festyn rodzinny w sobotę",     "2 dni temu",     COL["mint"]),
                ("Patrol policji wzmocniony",    "3 dni temu",     COL["aqua"]),
            ]
        elif name == "a3_pets":
            section_lbl = "ZWIERZAKI"
            items = [
                ("Burek (pies)",       "Zaginiony · 2 dni",  COL["coral"]),
                ("Mruczek (kot)",      "W domu",             COL["mint"]),
                ("Reksio (pies)",      "W domu",             COL["mint"]),
                ("Filemon (kot)",      "W domu",             COL["aqua"]),
            ]
        elif name == "b0_legal":
            section_lbl = "DOKUMENTY"
            items = [
                ("Regulamin",          "v2.3 · 04.2026",     COL["mint"]),
                ("Polityka prywatności","RODO compliant",     COL["mint"]),
                ("Licencje open-source","Flutter, Sentry…",   COL["aqua"]),
                ("Kontakt",            "kontakt@besafe.org.pl", COL["aqua"]),
            ]
        else:
            items = [(f"Pozycja {i+1}", "›", COL["mint"]) for i in range(5)]
        # Render
        inner.append(f'<text x="32" y="{body_y+30}" font-family="Inter" font-size="13" font-weight="600" letter-spacing="0.5" fill="{COL["label2"]}">{section_lbl}</text>')
        ly = body_y + 50
        rows_h = 56
        rows_n = len(items)
        inner.append(f'<rect x="16" y="{ly}" width="{W-32}" height="{rows_n*rows_h}" rx="10" fill="{COL["white"]}"/>')
        for i, (txt, val, ic) in enumerate(items):
            ry = ly + i*rows_h
            inner.append(f'<rect x="32" y="{ry+14}" width="28" height="28" rx="7" fill="{ic}" opacity="0.6"/>')
            # truncate label if too long
            short = txt if len(txt) < 28 else txt[:26] + "…"
            inner.append(f'<text x="72" y="{ry+30}" font-family="Inter" font-size="15" font-weight="500" fill="{COL["navy"]}">{short}</text>')
            inner.append(f'<text x="72" y="{ry+47}" font-family="Inter" font-size="12" fill="{COL["label2"]}">{val}</text>')
            inner.append(f'<text x="{W-44}" y="{ry+35}" text-anchor="end" font-family="Inter" font-size="17" fill="{COL["label2"]}">›</text>')
            if i < rows_n-1:
                inner.append(f'<line x1="72" y1="{ry+rows_h}" x2="{W-16}" y2="{ry+rows_h}" stroke="{COL["sep"]}" stroke-width="0.5"/>')

    elif kind == "detail":
        # Per-name real data
        if name == "21_alert_detail":
            a = ALERTS[0]
            d_title = a["title"]
            d_sub = f'{a["category"]} · {a["date"]} · m3n3s'
            d_body = "300 m od Twojej lokalizacji. Bądź ostrożny w okolicy ratusza."
            d_icon = COL["coral"]
            d_cta = "Potwierdź"
        elif name == "31_family_group":
            d_title = GROUPS[1]["name"]  # Grupa1 (najpopularniejsza)
            d_sub = f'{GROUPS[1]["members"]} osób · kod: {GROUPS[1]["invite"]}'
            d_body = "Zobacz wszystkich na mapie. Heluss, Justyna i Marcin online."
            d_icon = COL["mint"]
            d_cta = "Otwórz mapę"
        elif name == "41_ping_response":
            d_title = "Heluss pyta: gdzie jesteś?"
            d_sub = "12 min temu · Grupa1"
            d_body = "Wybierz odpowiedź lub udostępnij lokalizację."
            d_icon = COL["aqua"]
            d_cta = "Udostępnij lokalizację"
        else:
            d_title = "Tytuł"
            d_sub = "Podtytuł / status"
            d_body = "Opis treści…"
            d_icon = COL["mint"]
            d_cta = "Akcja"
        inner.append(f'<rect x="16" y="{body_y+20}" width="{W-32}" height="180" rx="20" fill="{COL["white"]}"/>')
        inner.append(f'<rect x="32" y="{body_y+36}" width="60" height="60" rx="14" fill="{d_icon}" opacity="0.4"/>')
        # truncate title
        ds = d_title if len(d_title) < 22 else d_title[:20] + "…"
        inner.append(f'<text x="108" y="{body_y+72}" font-family="Inter" font-size="20" font-weight="700" fill="{COL["navy"]}">{ds}</text>')
        inner.append(f'<text x="108" y="{body_y+96}" font-family="Inter" font-size="13" fill="{COL["label2"]}">{d_sub}</text>')
        inner.append(f'<text x="32" y="{body_y+140}" font-family="Inter" font-size="15" fill="{COL["navy"]}">{d_body[:48]}</text>')
        if len(d_body) > 48:
            inner.append(f'<text x="32" y="{body_y+160}" font-family="Inter" font-size="15" fill="{COL["navy"]}">{d_body[48:96]}</text>')
        # Action button
        inner.append(f'<rect x="16" y="{body_y+230}" width="{W-32}" height="52" rx="26" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W//2}" y="{body_y+263}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="600" fill="{COL["white"]}">{d_cta}</text>')

    elif kind == "profile":
        # Real members data
        if name == "36_child_profile":
            m = next((x for x in MEMBERS_GRUPA1 if x["name"] == "Heluss Menelek"), MEMBERS_GRUPA1[6])
            actions = ["Zadzwoń", "Wyślij sygnał", "Historia lokalizacji", "Bezpieczne trasy"]
        elif name == "35_member_profile":
            m = next((x for x in MEMBERS_GRUPA1 if x["name"] == "Marcin"), MEMBERS_GRUPA1[1])
            actions = ["Zadzwoń", "Wyślij sygnał", "Pokaż na mapie"]
        else:
            m = MEMBERS_GRUPA1[6]
            actions = ["Zadzwoń", "Wyślij sygnał", "Lokalizacja"]
        cx_ = W//2
        ay = body_y + 30
        inner.append(f'<rect x="16" y="{ay}" width="{W-32}" height="160" rx="20" fill="{COL["white"]}"/>')
        inner.append(f'<circle cx="{cx_}" cy="{ay+58}" r="36" fill="{COL["mint"] if not m["is_child"] else COL["coral"]}" opacity="0.6"/>')
        # initial
        init = m["name"][0].upper()
        inner.append(f'<text x="{cx_}" y="{ay+68}" text-anchor="middle" font-family="Inter" font-size="28" font-weight="700" fill="{COL["navy"]}">{init}</text>')
        nm = m["name"] if len(m["name"]) < 24 else m["name"][:22] + "…"
        inner.append(f'<text x="{cx_}" y="{ay+118}" text-anchor="middle" font-family="Inter" font-size="20" font-weight="700" fill="{COL["navy"]}">{nm}</text>')
        status = f'{"Dziecko" if m["is_child"] and m["role"]=="child" else m["role"].capitalize()} · {"Online" if m["online"] else "Offline"} · 🔋 {m["battery"]}%'
        inner.append(f'<text x="{cx_}" y="{ay+138}" text-anchor="middle" font-family="Inter" font-size="13" fill="{COL["label2"]}">{status}</text>')
        # List
        ly = ay + 184
        rows = len(actions)
        inner.append(f'<rect x="16" y="{ly}" width="{W-32}" height="{60*rows}" rx="10" fill="{COL["white"]}"/>')
        for i, lbl in enumerate(actions):
            ry = ly + i*60
            inner.append(f'<rect x="32" y="{ry+16}" width="28" height="28" rx="7" fill="{COL["aqua"]}" opacity="0.6"/>')
            inner.append(f'<text x="72" y="{ry+37}" font-family="Inter" font-size="17" fill="{COL["navy"]}">{lbl}</text>')
            inner.append(f'<text x="{W-44}" y="{ry+37}" text-anchor="end" font-family="Inter" font-size="17" fill="{COL["label2"]}">›</text>')

    elif kind == "chat":
        # Real Grupa1 members chat
        msgs = [
            (False, "Marcin: Cześć rodzino"),
            (False, "Heluss: Idę ze szkoły 🚶"),
            (True,  "OK, daj znać jak dojdziesz"),
            (False, "Justyna: Trening do 17"),
            (True,  "Wezmę Heluss po Cię"),
        ]
        my = body_y + 30
        for i, (mine, txt) in enumerate(msgs):
            bw = max(160, len(txt)*8)
            bx = (W - 24 - bw) if mine else 24
            bc = COL["mint"] if mine else "#E5E5EA"
            inner.append(f'<rect x="{bx}" y="{my + i*60}" width="{bw}" height="44" rx="18" fill="{bc}"/>')
            inner.append(f'<text x="{bx+14}" y="{my + i*60 + 28}" font-family="Inter" font-size="15" fill="{COL["navy"]}">{txt}</text>')
        # Input bar
        ib_y = body_y + body_h - 80
        inner.append(f'<rect x="16" y="{ib_y}" width="{W-78}" height="46" rx="23" fill="{COL["white"]}"/>')
        inner.append(f'<text x="32" y="{ib_y+30}" font-family="Inter" font-size="15" fill="{COL["label2"]}">Napisz…</text>')
        inner.append(f'<circle cx="{W-32}" cy="{ib_y+23}" r="22" fill="{COL["navy"]}"/>')
        inner.append(f'<text x="{W-32}" y="{ib_y+30}" text-anchor="middle" font-family="Inter" font-size="18" fill="{COL["white"]}">↑</text>')

    elif kind == "sos":
        # Big SOS orb with greeting
        if name == "34_family_sos":
            greeting = "Wyślij SOS do rodziny"
            cta = "Przytrzymaj 3 sekundy"
        elif name == "83_mental_health_sos":
            greeting = "Wsparcie psychologiczne"
            cta = "116 123 — telefon zaufania"
        elif name == "51_sos_kids":
            greeting = "Naciśnij i trzymaj"
            cta = "Mama i tata dostaną alarm"
        elif name == "52_sos_senior":
            greeting = "Wezwij pomoc"
            cta = "Duży przycisk · prosty alarm"
        else:
            greeting = f"Cześć {USER['display'].split()[0]}, jesteś bezpieczny?"
            cta = "Przytrzymaj 3 sekundy"
        inner.append(f'<text x="{W//2}" y="{body_y+30}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="600" fill="{COL["navy"]}">{greeting[:36]}</text>')
        cx_, cy_ = W//2, body_y + 220
        inner.append(f'<circle cx="{cx_}" cy="{cy_}" r="150" fill="{COL["coral"]}" opacity="0.18"/>')
        inner.append(f'<circle cx="{cx_}" cy="{cy_}" r="110" fill="{COL["coral"]}" opacity="0.35"/>')
        inner.append(f'<circle cx="{cx_}" cy="{cy_}" r="80" fill="{COL["coral"]}"/>')
        inner.append(f'<text x="{cx_}" y="{cy_+10}" text-anchor="middle" font-family="Inter" font-size="32" font-weight="800" fill="{COL["white"]}">SOS</text>')
        inner.append(f'<text x="{W//2}" y="{cy_+200}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="500" fill="{COL["navy"]}">{cta}</text>')
        # Bottom cancel
        bc_y = body_y + body_h - 90
        inner.append(f'<rect x="16" y="{bc_y}" width="{W-32}" height="52" rx="26" fill="{COL["white"]}"/>')
        inner.append(f'<text x="{W//2}" y="{bc_y+33}" text-anchor="middle" font-family="Inter" font-size="17" font-weight="600" fill="{COL["navy"]}">Anuluj</text>')

    elif kind == "stats":
        # Bars (real-ish based on m3n3s 8 alerts created 23.05.2026, reputation 104)
        bar_vals = [40, 80, 56, 100, 72, 90, 60]  # week
        for i, bh in enumerate(bar_vals[:5]):
            bx = 32 + i*60
            by = body_y + 40 + (220 - bh)
            inner.append(f'<rect x="{bx}" y="{by}" width="40" height="{bh}" rx="6" fill="{COL["mint"]}"/>')
        inner.append(f'<text x="32" y="{body_y+310}" font-family="Inter" font-size="13" font-weight="600" fill="{COL["label2"]}">OSTATNI TYDZIEŃ — {USER["username"]}</text>')
        stats_rows = [
            ("Zgłoszonych alertów",   str(len(ALERTS))),
            ("Potwierdzeń społeczności", "34"),
            ("Punkty reputacji",      f'+{USER["reputation"]}'),
        ]
        for i, (k, v) in enumerate(stats_rows):
            ly = body_y + 340 + i*44
            inner.append(f'<text x="32" y="{ly+20}" font-family="Inter" font-size="15" fill="{COL["navy"]}">{k}</text>')
            inner.append(f'<text x="{W-32}" y="{ly+20}" text-anchor="end" font-family="Inter" font-size="17" font-weight="600" fill="{COL["navy"]}">{v}</text>')

    # Dock (only on top-level screens - assume all show dock for design ref)
    dock_y = H - 70
    inner.append(f'<rect x="8" y="{dock_y}" width="{W-16}" height="56" rx="22" fill="{COL["navy"]}"/>')
    dock_icons = ["⌂", "♡", "👥", "⚠", "👤"]
    dock_labels = ["Mapa", "Home", "Rodzina", "SOS", "Profil"]
    for i, (ic, lb) in enumerate(zip(dock_icons, dock_labels)):
        dx = 8 + (W-16)//5 * i + (W-16)//10
        inner.append(f'<text x="{dx}" y="{dock_y+30}" text-anchor="middle" font-family="Inter" font-size="16" fill="{COL["white"]}" opacity="0.55">{ic}</text>')
        inner.append(f'<text x="{dx}" y="{dock_y+48}" text-anchor="middle" font-family="Inter" font-size="9" font-weight="500" fill="{COL["white"]}" opacity="0.55">{lb}</text>')

    # Frame border (subtle) + name label OUTSIDE the frame for grid view
    body = "\n      ".join(inner)
    g = f'''<g id="{name}" data-section="{section}" data-kind="{kind}" data-dart="{dart_path}" transform="translate({x_offset},{y_offset})">
    <title>{name}</title>
    <desc>{label} — {section} — {dart_path}</desc>
    <rect x="-1" y="-1" width="{W+2}" height="{H+2}" rx="20" fill="none" stroke="{COL["outline"]}" stroke-width="1"/>
    <clipPath id="clip_{name}"><rect x="0" y="0" width="{W}" height="{H}" rx="20"/></clipPath>
    <g clip-path="url(#clip_{name})">
      {body}
    </g>
    <text x="0" y="{H+28}" font-family="Inter, sans-serif" font-size="14" font-weight="700" fill="{COL["navy"]}">{name}</text>
    <text x="0" y="{H+48}" font-family="Inter" font-size="11" fill="{COL["label2"]}">{label}</text>
  </g>'''

    if embed:
        return g

    # standalone SVG
    full = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H+60}" viewBox="0 0 {W} {H+60}">
  <title>{name} — {label}</title>
  {g.replace(f'transform="translate({x_offset},{y_offset})"','')}
</svg>'''
    return full


# 1) Grid SVG with all frames
rows = (len(SCREENS) + COLS - 1) // COLS
total_w = PAD*2 + COLS*W + (COLS-1)*GAP
total_h = PAD*2 + rows*(H + 80) + (rows-1)*GAP

grid_inner = []
for idx, (name, section, kind, label, dart_path) in enumerate(SCREENS):
    col = idx % COLS
    row = idx // COLS
    x = PAD + col*(W + GAP)
    y = PAD + row*(H + 80 + GAP)
    grid_inner.append(make_frame_svg(name, section, kind, label, dart_path, x_offset=x, y_offset=y, embed=True))

# Header text on grid
header_h = 60
title_block = f'''<g id="_meta">
  <rect x="0" y="0" width="{total_w}" height="{header_h}" fill="{COL["grouped"]}"/>
  <text x="{PAD}" y="38" font-family="Inter" font-size="22" font-weight="700" fill="{COL["navy"]}">be:Safe — All Screens (44 frames)</text>
  <text x="{total_w - PAD}" y="38" text-anchor="end" font-family="Inter" font-size="13" fill="{COL["label2"]}">Design system: Serenity Guard · viewport 390×844</text>
</g>'''

grid_svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{total_w}" height="{total_h + header_h}" viewBox="0 0 {total_w} {total_h + header_h}">
  <title>be:Safe — All Screens</title>
  <desc>Auto-generated from mobile/lib/screens. Import to Figma via File → Import.</desc>
  <rect width="100%" height="100%" fill="{COL["grouped"]}"/>
  {title_block}
  <g transform="translate(0,{header_h})">
    {"".join(grid_inner)}
  </g>
</svg>'''

(OUT / "besafe_frames.svg").write_text(grid_svg)

# 2) Individual frame files
for name, section, kind, label, dart_path in SCREENS:
    svg = make_frame_svg(name, section, kind, label, dart_path, embed=False)
    (INDIV / f"{name}.svg").write_text(svg)

# 3) HTML index
html_cards = []
for name, section, kind, label, dart_path in SCREENS:
    html_cards.append(f'''
    <div class="card">
      <object data="besafe_frames_individual/{name}.svg" type="image/svg+xml" class="thumb"></object>
      <div class="meta">
        <div class="name">{name}</div>
        <div class="label">{label}</div>
        <div class="path">{dart_path}</div>
      </div>
    </div>''')

index_html = f'''<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8"/>
<title>be:Safe Figma Export — Preview</title>
<style>
  body {{ font-family: Inter, sans-serif; background: #F2F2F7; margin: 0; padding: 40px; color: #1A2027; }}
  h1 {{ font-weight: 700; font-size: 34px; margin: 0 0 8px; }}
  .sub {{ color: #8E8E93; margin-bottom: 32px; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 24px; }}
  .card {{ background: #FFF; border-radius: 16px; padding: 12px; box-shadow: 0 4px 20px rgba(26,32,39,0.06); }}
  .thumb {{ width: 100%; aspect-ratio: 390/904; display: block; border-radius: 12px; background: #F2F2F7; }}
  .meta {{ padding: 10px 4px 4px; }}
  .name {{ font-weight: 700; font-size: 13px; }}
  .label {{ color: #8E8E93; font-size: 12px; margin-top: 4px; }}
  .path {{ color: #C6C6C8; font-size: 10px; font-family: monospace; margin-top: 6px; }}
</style>
</head>
<body>
<h1>be:Safe — All Screens ({len(SCREENS)})</h1>
<div class="sub">Auto-generated from mobile/lib/screens · Serenity Guard design system · 390×844</div>
<div class="grid">{"".join(html_cards)}</div>
</body>
</html>'''
(OUT / "index.html").write_text(index_html)

print(f"✓ Generated {len(SCREENS)} frames")
print(f"  - Grid:        {OUT}/besafe_frames.svg")
print(f"  - Individual:  {INDIV}/ ({len(SCREENS)} files)")
print(f"  - Preview:     {OUT}/index.html")
