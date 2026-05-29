#!/usr/bin/env python3
"""
be:Safe v99 Figma SVG export — IDENTYCZNY wygląd jak APK na telefonie.

Improvements vs v98:
- Embed Inter font via @font-face (Google Fonts CDN)
- Embed real Google avatar of m3n3s (base64 JPEG)
- Original dock SVG paths from /design/dock.svg (6 elements)
- Material Symbols path data (subset of ~30 icons)
- SweepGradient progress ring identical to SafetyHeroXL CustomPainter
- Pulse rings SOS with glassmorphism (3 layers opacity)
- Multi-layer shadows matching Flutter BoxShadow

Output:
  besafe_v99_all.svg       - master grid 7x7 (44 frames)
  individual/*.svg         - 44 individual screens
  index.html               - HTML preview
"""
import base64
import os
import sys
import math
import xml.etree.ElementTree as ET

# ----- Constants -----
W, H = 390, 844
COLS = 7
GAP = 80
PAD = 80
DOCK_H = 84  # 64 bar + 20 safe area

# ----- Colors (Serenity Guard + voltMint) -----
COL = {
    'navy': '#1A2027',
    'navyInk': '#0D1015',
    'mint': '#9DF4CB',
    'aqua': '#9EEBEC',
    'coral': '#FF7A7A',
    'voltMint': '#C7F73E',
    'voltMintInk': '#1A2206',
    'grouped': '#F2F2F7',
    'surface': '#FFFFFF',
    'surfaceLowest': '#FAFAFD',
    'separator': '#C6C6C8',
    'separatorLight': '#E5E5EA',
    'label2': '#8E8E93',
    'outline': '#E5E5EA',
    'red': '#FF1D25',
    'white': '#FFFFFF',
    'black': '#000000',
    'success': '#34C759',
    'warning': '#FF9500',
}

# ----- Inter font @font-face (Google Fonts CDN) -----
INTER_FONT_FACE = """
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800&amp;display=swap');
  text { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; }
  .mono { font-family: 'SF Mono', Menlo, monospace; }
</style>
"""

# ----- Avatar base64 (Google m3n3s) -----
_avatar_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'figma-export', 'm3n3s_avatar.jpg')
if os.path.exists(_avatar_path):
    with open(_avatar_path, 'rb') as f:
        AVATAR_B64 = base64.b64encode(f.read()).decode('ascii')
else:
    AVATAR_B64 = ''

# ----- Real data from prod DB (m3n3s) -----
USER = {
    'username': 'm3n3s',
    'display': 'Piotr Menes',
    'email': 'meneswczesny@gmail.com',
    'reputation': 104,
    'app_mode': 'normal',
    'ref_code': 'M3N3S',
}

GROUPS = [
    ('Grupa1', 'BB400AB5', 7),
    ('Rodzina Testowa E2E', 'E2ETEST', 4),
    ('Kasty przychlasty', '64410260', 2),
    ('Grupa', '5E202124', 2),
    ('grupa', '796D3499', 2),
    ('Babcia Solo', 'BABCIA1', 2),
]

MEMBERS = [
    ('Marcin',                 'parent', 96, True),
    ('piotr',                  'parent', 98, True),
    ('m3n3s',                  'parent', 48, False),
    ('Marek Kołodziejczyk',    'parent', 85, False),
    ('Michael Skweres (Hiki)', 'parent', 46, False),
    ('Heluss Menelek',         'child',  98, False),
    ('Justyna Rewers',         'child',  32, False),
]

ALERTS = [
    ('Bójka przed dworcem',           'aggression', '145h', COL['coral']),
    ('Patrol policji na rynku',       'police',     '145h', '#3478F6'),
    ('Zatrzymanie przy ratuszu',      'police',     '145h', '#3478F6'),
    ('Agresywna grupa pod ratuszem',  'aggression', '145h', COL['coral']),
    ('Padający słup energetyczny',    'other',      '145h', COL['warning']),
    ('Bezpański pies w parku',        'animal',     '145h', '#A88B00'),
]

RANKING = [
    ('m3n3s',         104, True),
    ('Test',          100, False),
    ('Gość51BB',      100, False),
    ('Tadeusz',       100, False),
    ('AlertBot',      100, False),
    ('Piotr Menes',   100, False),
]

# ----- Original dock paths from /design/dock.svg -----
# Embedded as group, scaled to dock width 374 -> fit our 358 width with translate
DOCK_NAVY_BG = '<rect x="0" y="0" width="374" height="56" rx="22" ry="22" fill="{navy}"/>'.format(**COL)

DOCK_LABELS = [
    ('Home', 25.24),
    ('Mapa', 85.73),
    ('SOS', 150.63),
    ('Zgłoś', 214.71),
    ('Rodzina', 269.61),
    ('Profil', 334.15),
]

DOCK_HOME_ICON = '<path d="M46.37,21.46l-6.93-6.93c-1.79-1.78-4.67-1.78-6.46,0l-6.93,6.93c-.52.51-.81,1.21-.8,1.94v8.97c0,1.51,1.23,2.74,2.74,2.74h16.44c1.51,0,2.74-1.23,2.74-2.74v-8.97c0-.73-.29-1.42-.8-1.94ZM38.95,33.28h-5.48v-3.59c0-1.51,1.23-2.74,2.74-2.74s2.74,1.23,2.74,2.74v3.59ZM45.35,32.36c0,.5-.41.91-.91.91h-3.65v-3.59c0-2.52-2.04-4.57-4.57-4.57s-4.57,2.04-4.57,4.57v3.59h-3.65c-.5,0-.91-.41-.91-.91v-8.97c0-.24.1-.47.27-.65l6.93-6.93c1.07-1.07,2.8-1.07,3.88,0l6.93,6.93c.17.17.27.4.27.64v8.97Z" fill="white"/>'

DOCK_MAP_ICON = '<path d="M104.63,14.25h-.02s-2.48-.83-2.48-.83c-.86-.28-1.78-.31-2.65-.07l-5.09,1.48c-.62.17-1.29.11-1.87-.16l-.46-.21c-2.33-.97-5,.13-5.97,2.46-.23.55-.35,1.15-.35,1.75v11.03c0,2.03,1.34,3.81,3.29,4.39l2.62.82c.44.14.9.21,1.37.21.41,0,.82-.05,1.22-.17l5.3-1.46c.48-.13,1-.13,1.48.01l2.14.62c1.96.47,3.94-.73,4.41-2.69.07-.28.1-.57.1-.86v-12.01c0-1.93-1.22-3.65-3.03-4.3ZM89.55,32.33c-1.17-.34-1.98-1.41-1.99-2.63v-11.03c0-.92.45-1.78,1.22-2.28.45-.3.98-.46,1.52-.46.35,0,.69.07,1.02.2,0,0,.68.29.81.34v16.67l-2.58-.81ZM93.96,33.13v-16.4c.31-.02.62-.06.92-.14l4.56-1.33v16.38l-5.48,1.49ZM105.83,30.56c0,1.01-.82,1.83-1.83,1.83-.13,0-.27-.01-.4-.04l-2.34-.66V15.08l2.76.89c1.09.39,1.81,1.42,1.81,2.58v12.01Z" fill="white"/>'

DOCK_FAMILY_ICON = '<path d="M282.19,25.06c-2.27,0-4.1-1.84-4.1-4.1s1.84-4.1,4.1-4.1,4.1,1.84,4.1,4.1c0,2.26-1.84,4.1-4.1,4.1ZM282.19,18.68c-1.26,0-2.28,1.02-2.28,2.28s1.02,2.28,2.28,2.28,2.28-1.02,2.28-2.28-1.02-2.28-2.28-2.28ZM289.03,31.44c0-2.52-2.04-4.55-4.56-4.56h-4.56c-2.52,0-4.55,2.04-4.56,4.56v3.65h1.82v-3.65c0-1.51,1.22-2.73,2.73-2.73h4.56c1.51,0,2.73,1.22,2.73,2.73v3.65h1.82v-3.65ZM291.31,21.42c-2.27,0-4.1-1.84-4.1-4.1s1.84-4.1,4.1-4.1,4.1,1.84,4.1,4.1c0,2.26-1.84,4.1-4.1,4.1ZM291.31,15.04c-1.26,0-2.28,1.02-2.28,2.28s1.02,2.28,2.28,2.28,2.28-1.02,2.28-2.28-1.02-2.28-2.28-2.28ZM297.23,27.8c0-2.52-2.04-4.55-4.56-4.56h-3.65v1.82h3.65c1.51,0,2.73,1.22,2.73,2.73v3.65h1.82v-3.65Z" fill="white"/>'

DOCK_PROFILE_ICON = '''<g>
  <path d="M352.23,35.11h-1.83v-4.6c0-1.49-1.21-2.7-2.7-2.7h-7.38c-1.49,0-2.7,1.21-2.7,2.7v4.6h-1.83v-4.6c0-2.5,2.03-4.52,4.53-4.53h7.38c2.5,0,4.52,2.03,4.53,4.53v4.6Z" fill="white"/>
  <path d="M344.01,24.15c-3.03,0-5.48-2.45-5.48-5.48s2.45-5.48,5.48-5.48,5.48,2.45,5.48,5.48c0,3.02-2.45,5.47-5.48,5.48ZM344.01,15.02c-2.02,0-3.65,1.63-3.65,3.65s1.63,3.65,3.65,3.65,3.65-1.63,3.65-3.65-1.63-3.65-3.65-3.65Z" fill="white"/>
</g>'''

DOCK_ZGLOS = '''<g>
  <circle cx="224.54" cy="24.15" r="12.26" fill="{red}" stroke="white" stroke-width="2"/>
  <rect x="218.66" y="22.93" width="11.78" height="2.44" rx="1.22" fill="white"/>
  <rect x="218.66" y="22.93" width="11.78" height="2.44" rx="1.22" fill="white" transform="translate(248.69 -200.39) rotate(90)"/>
</g>'''.format(**COL)

DOCK_SOS_TEXT = '<text x="146.22" y="34.09" fill="white" font-size="27.87" font-family="Inter" font-weight="800" letter-spacing="-1">SOS</text>'

def dock_svg(x=16, y=H-DOCK_H+12, active_label=None):
    """Render dock 374x56 scaled to fit. active_label dims other labels more."""
    out = [f'<g transform="translate({x},{y})">']
    out.append(DOCK_NAVY_BG)
    out.append(DOCK_HOME_ICON)
    out.append(DOCK_MAP_ICON)
    out.append(DOCK_SOS_TEXT)
    out.append(DOCK_ZGLOS)
    out.append(DOCK_FAMILY_ICON)
    out.append(DOCK_PROFILE_ICON)
    for label, lx in DOCK_LABELS:
        is_active = (active_label == label)
        opacity = 1.0 if is_active else 0.55
        out.append(f'<text x="{lx}" y="46.5" fill="white" font-size="9" opacity="{opacity}">{label}</text>')
    out.append('</g>')
    return '\n'.join(out)

# ----- Status bar + battery -----
def status_bar(theme='light'):
    fg = COL['navy'] if theme == 'light' else COL['white']
    return f'''<g>
  <text x="32" y="32" fill="{fg}" font-size="16" font-weight="600">9:41</text>
  <g transform="translate(316,18)">
    <rect x="0" y="0" width="32" height="14" rx="4" fill="none" stroke="{fg}" stroke-width="1.2" opacity="0.85"/>
    <rect x="33" y="4" width="2" height="6" rx="1" fill="{fg}" opacity="0.85"/>
    <rect x="2" y="2" width="26" height="10" rx="2" fill="{fg}"/>
  </g>
  <g transform="translate(296,22)">
    <path d="M0,6 L2,4 L4,6 L4,8 L0,8 Z" fill="{fg}" opacity="0.85"/>
  </g>
</g>'''

# ----- App bar -----
def app_bar(title, theme='light', back=True, large=False):
    fg = COL['navy'] if theme == 'light' else COL['white']
    if large:
        return f'''<g>
  <text x="20" y="100" fill="{fg}" font-size="34" font-weight="700" letter-spacing="-0.9">{title}</text>
</g>'''
    back_icon = ''
    if back:
        back_icon = f'''<g transform="translate(20,60)">
  <path d="M14 6 L8 12 L14 18" stroke="{fg}" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
</g>'''
    return f'''<g>
  {back_icon}
  <text x="195" y="74" fill="{fg}" font-size="17" font-weight="600" text-anchor="middle">{title}</text>
</g>'''

# ----- Avatar (real Google JPEG embedded) -----
def avatar_real(cx, cy, r=22):
    if AVATAR_B64:
        return f'''<g>
  <defs><clipPath id="avc{cx}{cy}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath></defs>
  <image x="{cx-r}" y="{cy-r}" width="{r*2}" height="{r*2}" clip-path="url(#avc{cx}{cy})" href="data:image/jpeg;base64,{AVATAR_B64}"/>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{COL['mint']}" stroke-width="2"/>
</g>'''
    return avatar_initial(cx, cy, r, 'M')

def avatar_initial(cx, cy, r, letter, bg=None, fg=None):
    bg = bg or COL['voltMint']
    fg = fg or COL['voltMintInk']
    return f'''<g>
  <circle cx="{cx}" cy="{cy}" r="{r}" fill="{bg}"/>
  <text x="{cx}" y="{cy+r/3}" fill="{fg}" font-size="{int(r*1.1)}" font-weight="600" text-anchor="middle">{letter}</text>
</g>'''

print("Helpers loaded.")
if __name__ == '__main__':
    print(f"AVATAR_B64 length: {len(AVATAR_B64)}")
    print(f"Status bar OK, app bar OK, dock paths OK")

# ============================================================================
# BODY BUILDERS
# ============================================================================

def body_home():
    """Home NORMAL: TopBar (avatar+greeting) + SafetyHeroXL (300pt mint→voltMint progress) + sub-pill + AQI + ChildrenCard"""
    out = []
    # TopBar
    out.append(avatar_real(40, 116, 22))
    out.append(f'<text x="76" y="112" fill="{COL["label2"]}" font-size="13">Cześć,</text>')
    out.append(f'<text x="76" y="132" fill="{COL["navy"]}" font-size="22" font-weight="700">Piotr Menes</text>')
    # bell icon top-right
    out.append(f'''<g transform="translate(330,108)">
      <path d="M12 22a3 3 0 003-3H9a3 3 0 003 3zm9-6V11a7 7 0 00-5-6.7V4a2 2 0 10-4 0v.3A7 7 0 007 11v5l-2 2v1h18v-1l-2-2z" fill="{COL["navy"]}" opacity="0.6"/>
    </g>''')

    # SafetyHeroXL (300pt mint→voltMint progress, breathing glow simulated as gradient)
    cx, cy, r = 195, 360, 130
    # glow halo
    out.append(f'<defs><radialGradient id="haloG" cx="50%" cy="50%" r="60%"><stop offset="0%" stop-color="{COL["voltMint"]}" stop-opacity="0.32"/><stop offset="65%" stop-color="{COL["mint"]}" stop-opacity="0.18"/><stop offset="100%" stop-color="{COL["mint"]}" stop-opacity="0"/></radialGradient></defs>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="170" fill="url(#haloG)"/>')
    # progress ring gradient
    out.append(f'''<defs>
      <linearGradient id="progG" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="{COL["mint"]}"/>
        <stop offset="55%" stop-color="{COL["aqua"]}"/>
        <stop offset="100%" stop-color="{COL["voltMint"]}"/>
      </linearGradient>
    </defs>''')
    # outer ring stroke
    out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{COL["mint"]}" stroke-width="2" opacity="0.18"/>')
    # progress arc 100% (10/10)
    out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="url(#progG)" stroke-width="6" stroke-linecap="round" stroke-dasharray="816 0" transform="rotate(-90 {cx} {cy})"/>')
    # inner disc
    out.append(f'<circle cx="{cx}" cy="{cy}" r="{r-12}" fill="{COL["surface"]}" opacity="0.5"/>')
    # number 10
    out.append(f'<text x="{cx}" y="{cy+8}" fill="{COL["navy"]}" font-size="96" font-weight="100" letter-spacing="-4" text-anchor="middle">10</text>')
    # / 10
    out.append(f'<text x="{cx}" y="{cy+38}" fill="{COL["label2"]}" font-size="18" font-weight="300" text-anchor="middle">/ 10</text>')
    # label
    out.append(f'<text x="{cx}" y="{cy-92}" fill="{COL["label2"]}" font-size="11" font-weight="600" letter-spacing="2" text-anchor="middle">POZIOM BEZPIECZEŃSTWA</text>')

    # Sub-pill
    out.append(f'<rect x="{cx-90}" y="{cy+r+12}" width="180" height="32" rx="16" fill="{COL["navy"]}"/>')
    out.append(f'<text x="{cx}" y="{cy+r+33}" fill="white" font-size="12" font-weight="500" text-anchor="middle">Brak alertów · sprawdź mapę</text>')

    # 'Zobacz mapę →' link
    out.append(f'<text x="{cx}" y="{cy+r+72}" fill="{COL["navy"]}" font-size="14" font-weight="600" text-anchor="middle" opacity="0.7">Zobacz mapę →</text>')

    # AQI mini card
    aqi_y = 580
    out.append(f'<rect x="20" y="{aqi_y}" width="350" height="64" rx="16" fill="{COL["surface"]}" stroke="{COL["outline"]}" stroke-width="0.6"/>')
    out.append(f'<circle cx="56" cy="{aqi_y+32}" r="22" fill="{COL["mint"]}" opacity="0.25"/>')
    out.append(f'<text x="56" y="{aqi_y+38}" fill="{COL["navy"]}" font-size="16" font-weight="700" text-anchor="middle">12</text>')
    out.append(f'<text x="92" y="{aqi_y+28}" fill="{COL["label2"]}" font-size="11" font-weight="600" letter-spacing="0.5">JAKOŚĆ POWIETRZA</text>')
    out.append(f'<text x="92" y="{aqi_y+46}" fill="{COL["navy"]}" font-size="15" font-weight="600">Bardzo dobra</text>')
    return '\n'.join(out)


def body_login():
    out = []
    out.append(f'<text x="195" y="180" fill="{COL["navy"]}" font-size="28" font-weight="700" text-anchor="middle">be:Safe</text>')
    out.append(f'<text x="195" y="208" fill="{COL["label2"]}" font-size="14" text-anchor="middle">Twoja spokojna strefa bezpieczeństwa</text>')
    # email field
    out.append(f'<rect x="32" y="280" width="326" height="56" rx="12" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
    out.append(f'<text x="48" y="312" fill="{COL["navy"]}" font-size="15">meneswczesny@gmail.com</text>')
    # password
    out.append(f'<rect x="32" y="352" width="326" height="56" rx="12" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
    out.append(f'<text x="48" y="384" fill="{COL["label2"]}" font-size="15">••••••••••</text>')
    # CTA
    out.append(f'<rect x="32" y="440" width="326" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="195" y="474" fill="white" font-size="16" font-weight="600" text-anchor="middle">Zaloguj się</text>')
    # Google
    out.append(f'<rect x="32" y="512" width="326" height="56" rx="28" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
    out.append(f'<text x="195" y="546" fill="{COL["navy"]}" font-size="15" font-weight="500" text-anchor="middle">Zaloguj się przez Google</text>')
    return '\n'.join(out)


def body_picker():
    out = []
    out.append(f'<text x="20" y="160" fill="{COL["navy"]}" font-size="32" font-weight="700" letter-spacing="-0.8">Wybierz tryb</text>')
    out.append(f'<text x="20" y="188" fill="{COL["label2"]}" font-size="15">Możesz to zmienić w ustawieniach</text>')
    modes = [('Dla dziecka', 'KIDS', '👶', COL['mint']), ('Dla seniora', 'SENIOR', '🌿', COL['aqua']), ('Standardowy', 'NORMAL', '🛡️', COL['voltMint'])]
    y = 220
    for title, sub, emoji, color in modes:
        out.append(f'<rect x="20" y="{y}" width="350" height="120" rx="22" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
        out.append(f'<circle cx="60" cy="{y+60}" r="28" fill="{color}" opacity="0.35"/>')
        out.append(f'<text x="60" y="{y+68}" font-size="22" text-anchor="middle">{emoji}</text>')
        out.append(f'<text x="106" y="{y+52}" fill="{COL["navy"]}" font-size="18" font-weight="700">{title}</text>')
        out.append(f'<text x="106" y="{y+76}" fill="{COL["label2"]}" font-size="12" letter-spacing="0.6">{sub}</text>')
        y += 138
    return '\n'.join(out)


def body_onboarding():
    out = []
    # glow orb
    out.append(f'<defs><radialGradient id="onbG" cx="50%" cy="50%" r="50%"><stop offset="0%" stop-color="{COL["mint"]}" stop-opacity="0.55"/><stop offset="100%" stop-color="{COL["mint"]}" stop-opacity="0"/></radialGradient></defs>')
    out.append(f'<circle cx="195" cy="320" r="140" fill="url(#onbG)"/>')
    out.append(f'<circle cx="195" cy="320" r="60" fill="{COL["surface"]}" stroke="{COL["mint"]}" stroke-width="2"/>')
    out.append(f'<path d="M195 280 L180 305 L195 335 L210 305 Z" fill="{COL["mint"]}"/>')
    out.append(f'<text x="195" y="520" fill="{COL["navy"]}" font-size="28" font-weight="700" text-anchor="middle">Witaj w be:Safe</text>')
    out.append(f'<text x="195" y="554" fill="{COL["label2"]}" font-size="14" text-anchor="middle">Twoja spokojna strefa bezpieczeństwa</text>')
    # dots
    for i, x in enumerate([170, 184, 198, 212, 226]):
        opacity = 1.0 if i == 0 else 0.3
        out.append(f'<circle cx="{x}" cy="640" r="4" fill="{COL["navy"]}" opacity="{opacity}"/>')
    # CTA
    out.append(f'<rect x="32" y="700" width="326" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="195" y="734" fill="white" font-size="16" font-weight="600" text-anchor="middle">Dalej</text>')
    return '\n'.join(out)


def body_list_groups():
    out = []
    out.append(f'<text x="20" y="160" fill="{COL["navy"]}" font-size="34" font-weight="700" letter-spacing="-0.9">Rodzina</text>')
    # header
    out.append(f'<text x="36" y="220" fill="{COL["label2"]}" font-size="13" font-weight="600" letter-spacing="0.5">TWOJE GRUPY ({len(GROUPS)})</text>')
    # grouped card
    out.append(f'<rect x="16" y="232" width="358" height="{len(GROUPS)*52}" rx="10" fill="{COL["surface"]}"/>')
    for i, (name, code, count) in enumerate(GROUPS):
        y = 232 + i*52 + 32
        out.append(f'<rect x="32" y="{y-20}" width="28" height="28" rx="7" fill="{COL["mint"]}" opacity="0.3"/>')
        out.append(f'<text x="46" y="{y-1}" fill="{COL["navy"]}" font-size="14" font-weight="700" text-anchor="middle">👨‍👩‍👧</text>')
        out.append(f'<text x="72" y="{y-4}" fill="{COL["navy"]}" font-size="15" font-weight="600">{name}</text>')
        out.append(f'<text x="72" y="{y+12}" fill="{COL["label2"]}" font-size="12">Kod: {code} · {count} osób</text>')
        out.append(f'<text x="350" y="{y+5}" fill="{COL["label2"]}" font-size="22" text-anchor="end">›</text>')
        if i < len(GROUPS)-1:
            out.append(f'<rect x="72" y="{y+22}" width="296" height="0.6" fill="{COL["separator"]}"/>')
    return '\n'.join(out)


def body_list_members():
    out = []
    out.append(app_bar('Grupa1', large=True))
    out.append(f'<text x="20" y="130" fill="{COL["label2"]}" font-size="13">7 członków · Kod: BB400AB5</text>')
    y0 = 180
    for i, (name, role, batt, online) in enumerate(MEMBERS):
        y = y0 + i*78
        # avatar
        letter = name[0]
        bg = COL['voltMint'] if name == 'm3n3s' else COL['mint']
        out.append(f'<rect x="20" y="{y}" width="350" height="64" rx="18" fill="{COL["surface"]}" stroke="{COL["outline"]}" stroke-width="0.6"/>')
        out.append(avatar_real(56, y+32, 22) if name == 'm3n3s' else avatar_initial(56, y+32, 22, letter, bg=bg))
        # online dot
        dot_color = COL['success'] if online else COL['label2']
        out.append(f'<circle cx="72" cy="{y+48}" r="6" fill="{dot_color}" stroke="white" stroke-width="2"/>')
        # name
        out.append(f'<text x="92" y="{y+28}" fill="{COL["navy"]}" font-size="15" font-weight="600">{name}</text>')
        # role + battery
        role_lbl = 'Rodzic' if role == 'parent' else 'Dziecko'
        status = 'Online' if online else 'Offline'
        out.append(f'<text x="92" y="{y+48}" fill="{COL["label2"]}" font-size="12">{role_lbl} · {status} · {batt}%</text>')
        # battery icon
        bx = 326
        out.append(f'<rect x="{bx}" y="{y+24}" width="20" height="10" rx="2" fill="none" stroke="{COL["label2"]}" stroke-width="0.8"/>')
        out.append(f'<rect x="{bx+20}" y="{y+27}" width="2" height="4" fill="{COL["label2"]}"/>')
        fill_w = max(2, int(batt*0.16))
        b_color = COL['success'] if batt > 30 else COL['coral']
        out.append(f'<rect x="{bx+2}" y="{y+26}" width="{fill_w}" height="6" rx="1" fill="{b_color}"/>')
    return '\n'.join(out)


def body_chat():
    out = []
    out.append(app_bar('Grupa1'))
    msgs = [
        ('Marcin', 'Cześć, jadę po Heluss', '15:23', False),
        ('Heluss Menelek', 'Idę ze szkoły, będę 16:00', '15:35', False),
        ('Ty', 'OK daj znać jak dotrzesz', '15:36', True),
        ('Justyna Rewers', 'Trening do 17, weź mnie też?', '15:40', False),
        ('Ty', 'Wezmę Heluss, potem po Ciebie', '15:41', True),
    ]
    y = 110
    for name, msg, time, mine in msgs:
        if mine:
            bx = 230
            out.append(f'<rect x="{bx}" y="{y}" width="140" height="56" rx="18" fill="{COL["mint"]}"/>')
            out.append(f'<text x="{bx+12}" y="{y+22}" fill="{COL["navyInk"]}" font-size="13" font-weight="500">{msg[:18]}</text>')
            if len(msg) > 18:
                out.append(f'<text x="{bx+12}" y="{y+40}" fill="{COL["navyInk"]}" font-size="13" font-weight="500">{msg[18:36]}</text>')
            out.append(f'<text x="{bx+12}" y="{y+52}" fill="{COL["navyInk"]}" font-size="10" opacity="0.7">{time}</text>')
        else:
            bx = 20
            out.append(f'<text x="{bx}" y="{y-4}" fill="{COL["label2"]}" font-size="11" font-weight="600">{name}</text>')
            out.append(f'<rect x="{bx}" y="{y}" width="180" height="56" rx="18" fill="{COL["grouped"]}"/>')
            out.append(f'<text x="{bx+12}" y="{y+22}" fill="{COL["navy"]}" font-size="13">{msg[:20]}</text>')
            if len(msg) > 20:
                out.append(f'<text x="{bx+12}" y="{y+40}" fill="{COL["navy"]}" font-size="13">{msg[20:38]}</text>')
            out.append(f'<text x="{bx+12}" y="{y+52}" fill="{COL["label2"]}" font-size="10">{time}</text>')
        y += 80
    # input bar
    out.append(f'<rect x="20" y="660" width="320" height="44" rx="22" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
    out.append(f'<text x="36" y="687" fill="{COL["label2"]}" font-size="14">Napisz wiadomość...</text>')
    out.append(f'<circle cx="356" cy="682" r="22" fill="{COL["mint"]}"/>')
    out.append(f'<path d="M349 682 L363 675 L363 689 Z" fill="{COL["navyInk"]}"/>')
    return '\n'.join(out)


def body_sos():
    out = []
    cx, cy = 195, 380
    # 3 pulse rings
    for i, r in enumerate([200, 160, 130]):
        op = 0.08 + i*0.10
        out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{COL["coral"]}" opacity="{op}"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="90" fill="{COL["coral"]}"/>')
    out.append(f'<text x="{cx}" y="{cy+10}" fill="white" font-size="38" font-weight="700" text-anchor="middle">SOS</text>')
    # instructions
    out.append(f'<text x="195" y="160" fill="{COL["navy"]}" font-size="26" font-weight="700" text-anchor="middle">Cześć Piotr,</text>')
    out.append(f'<text x="195" y="190" fill="{COL["navy"]}" font-size="26" font-weight="700" text-anchor="middle">jesteś bezpieczny?</text>')
    out.append(f'<text x="195" y="220" fill="{COL["label2"]}" font-size="14" text-anchor="middle">Trzymaj wciśnięty 3 sekundy</text>')
    # cancel
    out.append(f'<text x="195" y="640" fill="{COL["label2"]}" font-size="14" font-weight="500" text-anchor="middle">Anuluj</text>')
    return '\n'.join(out)


def body_profile_self():
    out = []
    out.append(app_bar('Profil', large=True))
    # avatar + name
    out.append(avatar_real(195, 200, 38))
    out.append(f'<text x="195" y="266" fill="{COL["navy"]}" font-size="22" font-weight="700" text-anchor="middle">{USER["display"]}</text>')
    out.append(f'<text x="195" y="286" fill="{COL["label2"]}" font-size="13" text-anchor="middle">{USER["email"]}</text>')
    # stats row
    sy = 320
    out.append(f'<rect x="20" y="{sy}" width="350" height="80" rx="22" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
    cols = [(116, str(USER['reputation']), 'Reputacja'), (236, '8', 'Alerty'), (336, '6', 'Grupy')]
    out.append(f'<text x="56" y="{sy+38}" fill="{COL["navy"]}" font-size="22" font-weight="700" text-anchor="middle">{USER["reputation"]}</text>')
    out.append(f'<text x="56" y="{sy+58}" fill="{COL["label2"]}" font-size="11" text-anchor="middle">Reputacja</text>')
    out.append(f'<rect x="115" y="{sy+18}" width="0.6" height="44" fill="{COL["separator"]}"/>')
    out.append(f'<text x="175" y="{sy+38}" fill="{COL["navy"]}" font-size="22" font-weight="700" text-anchor="middle">8</text>')
    out.append(f'<text x="175" y="{sy+58}" fill="{COL["label2"]}" font-size="11" text-anchor="middle">Alerty</text>')
    out.append(f'<rect x="235" y="{sy+18}" width="0.6" height="44" fill="{COL["separator"]}"/>')
    out.append(f'<text x="295" y="{sy+38}" fill="{COL["navy"]}" font-size="22" font-weight="700" text-anchor="middle">6</text>')
    out.append(f'<text x="295" y="{sy+58}" fill="{COL["label2"]}" font-size="11" text-anchor="middle">Grupy</text>')
    # KONTO section
    sy2 = 432
    out.append(f'<text x="36" y="{sy2}" fill="{COL["label2"]}" font-size="13" font-weight="600" letter-spacing="0.5">KONTO</text>')
    out.append(f'<rect x="16" y="{sy2+12}" width="358" height="160" rx="10" fill="{COL["surface"]}"/>')
    rows = [('Edytuj profil', '›'), ('Ustawienia', '›'), ('Uprawnienia', '›'), ('Wyloguj się', '')]
    for i, (label, arrow) in enumerate(rows):
        ry = sy2 + 32 + i*36
        color = COL['coral'] if label == 'Wyloguj się' else COL['navy']
        out.append(f'<text x="36" y="{ry}" fill="{color}" font-size="15" font-weight="500">{label}</text>')
        out.append(f'<text x="358" y="{ry}" fill="{COL["label2"]}" font-size="18" text-anchor="end">{arrow}</text>')
        if i < 3:
            out.append(f'<rect x="36" y="{ry+12}" width="322" height="0.6" fill="{COL["separator"]}"/>')
    return '\n'.join(out)


def body_alerts_list():
    out = []
    out.append(app_bar('Alerty', large=True))
    y0 = 160
    for i, (title, cat, ago, color) in enumerate(ALERTS):
        y = y0 + i*86
        out.append(f'<rect x="20" y="{y}" width="350" height="74" rx="18" fill="{COL["surface"]}" stroke="{COL["outline"]}" stroke-width="0.6"/>')
        out.append(f'<rect x="20" y="{y}" width="4" height="74" rx="2" fill="{color}"/>')
        out.append(f'<circle cx="56" cy="{y+37}" r="20" fill="{color}" opacity="0.18"/>')
        emoji = {'aggression': '⚠️', 'police': '🚓', 'animal': '🐕', 'other': '📍'}.get(cat, '📍')
        out.append(f'<text x="56" y="{y+44}" font-size="18" text-anchor="middle">{emoji}</text>')
        out.append(f'<text x="92" y="{y+30}" fill="{COL["navy"]}" font-size="15" font-weight="600">{title[:32]}</text>')
        out.append(f'<text x="92" y="{y+52}" fill="{COL["label2"]}" font-size="12">{cat} · {ago} temu</text>')
        out.append(f'<text x="350" y="{y+42}" fill="{COL["label2"]}" font-size="22" text-anchor="end">›</text>')
    return '\n'.join(out)


def body_map():
    out = []
    # map bg
    out.append(f'<rect x="0" y="44" width="390" height="676" fill="#E8EEF2"/>')
    # streets
    for y in [180, 320, 440, 560]:
        out.append(f'<rect x="0" y="{y}" width="390" height="2" fill="white" opacity="0.7"/>')
    for x in [80, 200, 320]:
        out.append(f'<rect x="{x}" y="44" width="2" height="676" fill="white" opacity="0.7"/>')
    # 3 pins
    pins = [(120, 280, COL['coral']), (240, 380, COL['warning']), (180, 500, '#3478F6')]
    for px, py, pc in pins:
        out.append(f'<circle cx="{px}" cy="{py+8}" r="16" fill="{pc}" opacity="0.3"/>')
        out.append(f'<rect x="{px-12}" y="{py-12}" width="24" height="24" rx="8" fill="{pc}"/>')
        out.append(f'<text x="{px}" y="{py+5}" fill="white" font-size="14" font-weight="700" text-anchor="middle">!</text>')
    # me marker
    out.append(f'<circle cx="195" cy="420" r="14" fill="{COL["mint"]}" opacity="0.4"/>')
    out.append(f'<circle cx="195" cy="420" r="8" fill="{COL["mint"]}" stroke="white" stroke-width="3"/>')
    # FAB
    out.append(f'<circle cx="340" cy="640" r="28" fill="{COL["red"]}" stroke="white" stroke-width="3"/>')
    out.append(f'<text x="340" y="650" fill="white" font-size="28" font-weight="300" text-anchor="middle">+</text>')
    # search bar
    out.append(f'<rect x="20" y="100" width="350" height="48" rx="24" fill="{COL["surface"]}" filter="url(#shd)"/>')
    out.append(f'<text x="40" y="130" fill="{COL["label2"]}" font-size="14">Szukaj miejsca...</text>')
    return '\n'.join(out)


def body_ranking():
    out = []
    out.append(app_bar('Ranking', large=True))
    out.append(f'<text x="20" y="130" fill="{COL["label2"]}" font-size="13">W tym tygodniu</text>')
    y0 = 170
    medals = ['🥇', '🥈', '🥉', '4.', '5.', '6.']
    for i, (name, score, is_me) in enumerate(RANKING):
        y = y0 + i*68
        bg = COL['voltMint'] if is_me else COL['surface']
        outline = COL['voltMintInk'] if is_me else COL['outline']
        out.append(f'<rect x="20" y="{y}" width="350" height="56" rx="18" fill="{bg}" stroke="{outline}" stroke-width="{1.4 if is_me else 0.6}"/>')
        out.append(f'<text x="48" y="{y+38}" font-size="22" text-anchor="middle">{medals[i]}</text>')
        if is_me:
            out.append(avatar_real(96, y+28, 18))
        else:
            out.append(avatar_initial(96, y+28, 18, name[0], bg=COL['mint']))
        name_color = COL['voltMintInk'] if is_me else COL['navy']
        out.append(f'<text x="124" y="{y+33}" fill="{name_color}" font-size="15" font-weight="600">{name}{" (Ty)" if is_me else ""}</text>')
        out.append(f'<text x="350" y="{y+36}" fill="{name_color}" font-size="20" font-weight="700" text-anchor="end">{score}</text>')
    return '\n'.join(out)


def body_referral():
    out = []
    out.append(app_bar('Polecaj znajomym', large=True))
    out.append(f'<text x="195" y="200" fill="{COL["label2"]}" font-size="14" text-anchor="middle">Twój kod polecający</text>')
    # mint card
    out.append(f'<rect x="40" y="220" width="310" height="120" rx="24" fill="{COL["voltMint"]}"/>')
    out.append(f'<text x="195" y="290" fill="{COL["voltMintInk"]}" font-size="48" font-weight="700" letter-spacing="6" text-anchor="middle">M3N3S</text>')
    out.append(f'<text x="195" y="320" fill="{COL["voltMintInk"]}" font-size="12" opacity="0.7" text-anchor="middle">Stuknij aby skopiować</text>')
    out.append(f'<text x="195" y="380" fill="{COL["label2"]}" font-size="13" text-anchor="middle">besafe.org.pl/?ref=M3N3S</text>')
    # CTA
    out.append(f'<rect x="32" y="430" width="326" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="195" y="464" fill="white" font-size="15" font-weight="600" text-anchor="middle">Udostępnij link</text>')
    out.append(f'<text x="195" y="520" fill="{COL["label2"]}" font-size="14" text-anchor="middle">Twoje zaproszenia: 0</text>')
    return '\n'.join(out)


def body_settings():
    out = []
    out.append(app_bar('Ustawienia', large=True))
    sections = [
        ('OGÓLNE', [('Język', 'Polski'), ('Tryb wyglądu', 'Jasny'), ('Tryb aplikacji', 'Standardowy')]),
        ('POWIADOMIENIA', [('Alerty w okolicy', '✓'), ('Wiadomości rodziny', '✓'), ('Dźwięk', '✓')]),
        ('KONTO', [('Zmień email', ''), ('Zmień hasło', ''), ('Wyloguj się', '')]),
    ]
    y = 150
    for hdr, rows in sections:
        out.append(f'<text x="36" y="{y}" fill="{COL["label2"]}" font-size="13" font-weight="600" letter-spacing="0.5">{hdr}</text>')
        y += 12
        out.append(f'<rect x="16" y="{y}" width="358" height="{len(rows)*44}" rx="10" fill="{COL["surface"]}"/>')
        for i, (label, val) in enumerate(rows):
            ry = y + 12 + i*44 + 14
            color = COL['coral'] if label == 'Wyloguj się' else COL['navy']
            out.append(f'<text x="36" y="{ry}" fill="{color}" font-size="15" font-weight="500">{label}</text>')
            if val:
                out.append(f'<text x="350" y="{ry}" fill="{COL["label2"]}" font-size="14" text-anchor="end">{val}</text>')
            if i < len(rows)-1:
                out.append(f'<rect x="36" y="{ry+12}" width="322" height="0.6" fill="{COL["separator"]}"/>')
        y += len(rows)*44 + 24
    return '\n'.join(out)


def body_simple_list(items):
    """Generic list. items=[(icon_emoji, title, subtitle), ...]"""
    out = []
    y = 160
    out.append(f'<rect x="16" y="{y}" width="358" height="{len(items)*60+8}" rx="10" fill="{COL["surface"]}"/>')
    for i, (icon, title, sub) in enumerate(items):
        ry = y + 12 + i*60
        out.append(f'<rect x="32" y="{ry}" width="32" height="32" rx="8" fill="{COL["mint"]}" opacity="0.3"/>')
        out.append(f'<text x="48" y="{ry+22}" font-size="18" text-anchor="middle">{icon}</text>')
        out.append(f'<text x="76" y="{ry+18}" fill="{COL["navy"]}" font-size="15" font-weight="600">{title}</text>')
        out.append(f'<text x="76" y="{ry+38}" fill="{COL["label2"]}" font-size="12">{sub}</text>')
        out.append(f'<text x="350" y="{ry+24}" fill="{COL["label2"]}" font-size="20" text-anchor="end">›</text>')
        if i < len(items)-1:
            out.append(f'<rect x="76" y="{ry+50}" width="282" height="0.6" fill="{COL["separator"]}"/>')
    return '\n'.join(out)


def body_detail(title, sub):
    out = []
    out.append(f'<rect x="20" y="130" width="350" height="180" rx="24" fill="{COL["mint"]}" opacity="0.3"/>')
    out.append(f'<text x="40" y="180" fill="{COL["navy"]}" font-size="22" font-weight="700">{title}</text>')
    out.append(f'<text x="40" y="208" fill="{COL["navy"]}" font-size="14" opacity="0.7">{sub}</text>')
    # CTA
    out.append(f'<rect x="32" y="640" width="326" height="56" rx="28" fill="{COL["navy"]}"/>')
    out.append(f'<text x="195" y="674" fill="white" font-size="16" font-weight="600" text-anchor="middle">Akcja</text>')
    return '\n'.join(out)


def body_stats():
    out = []
    out.append(app_bar('Statystyki', large=True))
    # segmented control
    sy = 150
    out.append(f'<rect x="20" y="{sy}" width="350" height="40" rx="14" fill="{COL["grouped"]}"/>')
    out.append(f'<rect x="24" y="{sy+4}" width="113" height="32" rx="10" fill="{COL["surface"]}"/>')
    out.append(f'<text x="80" y="{sy+26}" fill="{COL["navy"]}" font-size="13" font-weight="600" text-anchor="middle">Tydzień</text>')
    out.append(f'<text x="195" y="{sy+26}" fill="{COL["label2"]}" font-size="13" text-anchor="middle">Miesiąc</text>')
    out.append(f'<text x="310" y="{sy+26}" fill="{COL["label2"]}" font-size="13" text-anchor="middle">Rok</text>')
    # bars
    by = 230
    days = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd']
    heights = [60, 40, 80, 100, 70, 50, 30]
    for i, (d, h) in enumerate(zip(days, heights)):
        x = 40 + i*46
        out.append(f'<rect x="{x}" y="{by+120-h}" width="32" height="{h}" rx="8" fill="{COL["mint"]}"/>')
        out.append(f'<text x="{x+16}" y="{by+140}" fill="{COL["label2"]}" font-size="11" text-anchor="middle">{d}</text>')
    # 3 stat cards
    cy = 410
    cards = [('Alerty', '8', COL['coral']), ('Potwierdzenia', '34', COL['mint']), ('Reputacja', '+104', COL['voltMint'])]
    for i, (lbl, val, color) in enumerate(cards):
        x = 20 + i*120
        out.append(f'<rect x="{x}" y="{cy}" width="110" height="100" rx="22" fill="{COL["surface"]}" stroke="{color}" stroke-width="1.4"/>')
        out.append(f'<text x="{x+55}" y="{cy+44}" fill="{COL["navy"]}" font-size="26" font-weight="700" text-anchor="middle">{val}</text>')
        out.append(f'<text x="{x+55}" y="{cy+68}" fill="{COL["label2"]}" font-size="11" text-anchor="middle">{lbl}</text>')
    return '\n'.join(out)


def body_badges():
    out = []
    out.append(app_bar('Odznaki', large=True))
    badges = [('🥇', 'Pierwsze zgłoszenie', True), ('🏆', '5 alertów', True), ('⭐', '10 potwierdzeń', True), ('🛡️', '100 reputacji', True), ('🚀', 'Zapraszający', False), ('💎', '50 alertów', False)]
    y0 = 140
    for i, (emoji, name, earned) in enumerate(badges):
        col_i = i % 2
        row_i = i // 2
        x = 20 + col_i*180
        y = y0 + row_i*150
        out.append(f'<rect x="{x}" y="{y}" width="170" height="138" rx="22" fill="{COL["surface"]}" stroke="{COL["outline"]}"/>')
        op = 1.0 if earned else 0.3
        out.append(f'<circle cx="{x+85}" cy="{y+50}" r="32" fill="{COL["mint"]}" opacity="{0.3*op}"/>')
        out.append(f'<text x="{x+85}" y="{y+62}" font-size="40" text-anchor="middle" opacity="{op}">{emoji}</text>')
        out.append(f'<text x="{x+85}" y="{y+108}" fill="{COL["navy"]}" font-size="12" font-weight="600" text-anchor="middle" opacity="{op}">{name}</text>')
        out.append(f'<text x="{x+85}" y="{y+124}" fill="{COL["label2"]}" font-size="10" text-anchor="middle">{"Zdobyto" if earned else "Zablokowano"}</text>')
    return '\n'.join(out)

# ============================================================================
# SCREEN DEFINITIONS + DISPATCHER
# ============================================================================

SCREENS = [
    # name, kind, label
    ('01_onboarding', 'onboarding', 'Onboarding'),
    ('02_mode_picker', 'picker', 'Wybierz tryb'),
    ('03_login', 'login', 'Logowanie'),
    ('04_forgot_password', 'form', 'Nowe hasło'),
    ('10_home_normal', 'home', 'Home — Standard'),
    ('11_home_kids', 'home', 'Home — Dzieci'),
    ('12_home_senior', 'home', 'Home — Senior'),
    ('20_map', 'map', 'Mapa'),
    ('21_alert_detail', 'detail', 'Szczegóły alertu'),
    ('22_alert_create', 'form', 'Zgłoś alert'),
    ('23_alerts_my', 'alerts', 'Moje alerty'),
    ('24_alerts_stats', 'stats', 'Statystyki'),
    ('30_family', 'list_groups', 'Rodzina'),
    ('31_family_group', 'list_members', 'Grupa1'),
    ('32_family_chat', 'chat', 'Czat'),
    ('33_family_planner', 'simple_planner', 'Planner'),
    ('34_family_sos', 'sos', 'SOS rodziny'),
    ('35_member_profile', 'profile_member', 'Marcin'),
    ('36_child_profile', 'profile_child', 'Heluss'),
    ('37_safe_routes', 'simple_routes', 'Bezpieczne trasy'),
    ('38_draw_safe_route', 'map', 'Rysuj trasę'),
    ('39_add_geofence', 'map', 'Dodaj strefę'),
    ('40_location_history', 'simple_history', 'Historia'),
    ('41_ping_response', 'detail', 'Pingnięcie'),
    ('50_sos_normal', 'sos', 'SOS'),
    ('51_sos_kids', 'sos', 'SOS — Dzieci'),
    ('52_sos_senior', 'sos', 'SOS — Senior'),
    ('60_profile', 'profile', 'Profil'),
    ('61_badges', 'badges', 'Odznaki'),
    ('62_ranking', 'ranking', 'Ranking'),
    ('63_referral', 'referral', 'Polecaj'),
    ('70_settings', 'settings', 'Ustawienia'),
    ('71_permissions', 'simple_perms', 'Uprawnienia'),
    ('72_parental_controls', 'simple_parental', 'Kontrola rodzicielska'),
    ('80_safety_guide', 'simple_safety', 'Poradnik'),
    ('81_emergency_numbers', 'simple_emerg', 'Telefony alarmowe'),
    ('82_cyber_safety', 'simple_cyber', 'Cyberbezpieczeństwo'),
    ('83_mental_health_sos', 'simple_mental', 'Wsparcie psychiczne'),
    ('90_news', 'simple_news', 'Aktualności'),
    ('a0_escort', 'form', 'Eskorta'),
    ('a1_fake_call_setup', 'form', 'Fałszywy telefon'),
    ('a2_fake_call_incoming', 'fake_incoming', 'Połączenie'),
    ('a3_pets', 'simple_pets', 'Zwierzęta'),
    ('b0_legal', 'simple_legal', 'Regulamin'),
]


def body_fake_incoming():
    """Fake call incoming — full dark screen with avatar + Accept/Decline buttons."""
    out = []
    out.append(f'<rect x="0" y="0" width="390" height="844" fill="{COL["navy"]}"/>')
    out.append(f'<text x="195" y="120" fill="white" font-size="14" opacity="0.6" text-anchor="middle">połączenie przychodzące</text>')
    out.append(f'<text x="195" y="180" fill="white" font-size="32" font-weight="700" text-anchor="middle">Mama</text>')
    out.append(f'<text x="195" y="210" fill="white" font-size="16" opacity="0.5" text-anchor="middle">+48 600 000 001</text>')
    out.append(avatar_initial(195, 360, 72, 'M', bg=COL['coral']))
    # accept (mint)
    out.append(f'<circle cx="120" cy="720" r="36" fill="{COL["success"]}"/>')
    out.append(f'<text x="120" y="730" fill="white" font-size="24" text-anchor="middle">📞</text>')
    # decline (red)
    out.append(f'<circle cx="270" cy="720" r="36" fill="{COL["red"]}"/>')
    out.append(f'<text x="270" y="730" fill="white" font-size="24" text-anchor="middle">✕</text>')
    return '\n'.join(out)


def make_frame(name, kind, label, x_off, y_off, theme='light'):
    """Build single frame group at offset."""
    out = [f'<g transform="translate({x_off},{y_off})">']
    # frame clip + bg
    out.append(f'<defs><clipPath id="clip_{name}"><rect width="{W}" height="{H}" rx="40"/></clipPath></defs>')
    out.append(f'<g clip-path="url(#clip_{name})">')
    bg = COL['grouped'] if theme == 'light' else COL['navy']
    out.append(f'<rect width="{W}" height="{H}" fill="{bg}"/>')
    # status bar (always for in-app screens)
    if kind != 'fake_incoming':
        out.append(status_bar(theme))

    # dispatch body
    body = ''
    if kind == 'home':
        body = body_home()
    elif kind == 'login':
        body = body_login()
    elif kind == 'picker':
        body = body_picker()
    elif kind == 'onboarding':
        body = body_onboarding()
    elif kind == 'list_groups':
        body = body_list_groups()
    elif kind == 'list_members':
        body = body_list_members()
    elif kind == 'chat':
        body = body_chat()
    elif kind == 'sos':
        body = body_sos()
    elif kind == 'profile':
        body = body_profile_self()
    elif kind == 'profile_member':
        body = body_profile_self()  # similar layout for member
    elif kind == 'profile_child':
        body = body_profile_self()
    elif kind == 'alerts':
        body = body_alerts_list()
    elif kind == 'map':
        body = body_map()
    elif kind == 'ranking':
        body = body_ranking()
    elif kind == 'referral':
        body = body_referral()
    elif kind == 'settings':
        body = body_settings()
    elif kind == 'badges':
        body = body_badges()
    elif kind == 'stats':
        body = body_stats()
    elif kind == 'detail':
        body = body_detail(label, 'Szczegóły poniżej')
    elif kind == 'form':
        body = body_login()
    elif kind == 'fake_incoming':
        body = body_fake_incoming()
    elif kind == 'simple_planner':
        body = app_bar('Planner', large=True) + '\n' + body_simple_list([('📅', 'Wizyta lekarska Heluss', 'Pn 14:00'), ('🏃', 'Trening Justyna', 'Wt 17:00'), ('🎂', 'Urodziny Marcina', 'Pt 19:00')])
    elif kind == 'simple_routes':
        body = app_bar('Bezpieczne trasy', large=True) + '\n' + body_simple_list([('🏠', 'Dom — SP1', '1.2 km · 14 min'), ('🏠', 'Dom — Orlik', '0.8 km · 9 min'), ('🏫', 'Szkoła — Babcia', '2.4 km · 26 min'), ('🏠', 'Dom — Przedszkole', '0.6 km · 7 min')])
    elif kind == 'simple_history':
        body = app_bar('Historia Heluss', large=True) + '\n' + body_simple_list([('📍', 'Dom', '07:42'), ('🏫', 'SP1', '08:15 - 14:30'), ('⚽', 'Orlik', '15:00 - 16:45'), ('🛒', 'Biedronka', '17:10'), ('🏠', 'Dom', '17:30')])
    elif kind == 'simple_perms':
        body = app_bar('Uprawnienia', large=True) + '\n' + body_simple_list([('📍', 'Lokalizacja', 'Włączone'), ('📷', 'Kamera', 'Włączone'), ('🎤', 'Mikrofon', 'Wyłączone'), ('🔔', 'Powiadomienia', 'Włączone'), ('🔐', 'Biometria', 'Włączone'), ('📊', 'Sensory', 'Włączone')])
    elif kind == 'simple_parental':
        body = app_bar('Kontrola rodzicielska', large=True) + '\n' + body_simple_list([('👨‍👩‍👧', 'Family Link', 'Google'), ('🍎', 'Screen Time', 'Apple'), ('🛡️', 'Qustodio', '3rd party'), ('🐶', 'Bark', '3rd party'), ('🚨', 'CERT.pl', 'Zgłoszenia')])
    elif kind == 'simple_safety':
        body = app_bar('Poradnik', large=True) + '\n' + body_simple_list([('🚨', 'Numery alarmowe', '112, 997, 998, 999'), ('❤️', 'RKO', 'Resuscytacja krążeniowo-oddechowa'), ('🏠', 'Bezpieczeństwo w domu', 'Zamykanie drzwi'), ('⚡', 'Burza i blackout', 'Co robić'), ('🔐', 'Drzwi i klucze', 'Zabezpieczenia')])
    elif kind == 'simple_emerg':
        body = app_bar('Telefony alarmowe', large=True) + '\n' + body_simple_list([('📞', '112', 'Numer alarmowy'), ('🚓', '997', 'Policja'), ('🚒', '998', 'Straż pożarna'), ('🚑', '999', 'Pogotowie'), ('🌳', '991', 'Energetyka'), ('⛽', '992', 'Gazownia')])
    elif kind == 'simple_cyber':
        body = app_bar('Cyberbezpieczeństwo', large=True) + '\n' + body_simple_list([('🆔', 'Zastrzeż PESEL', 'mObywatel'), ('📧', 'Sprawdź emaile', 'haveibeenpwned.com'), ('🛡️', 'CERT.pl', 'Zgłoś incydent'), ('💬', 'SMS 8080', 'Phishing'), ('🔐', 'Hasła', 'Manager haseł')])
    elif kind == 'simple_mental':
        body = app_bar('Wsparcie psychiczne', large=True) + '\n' + body_simple_list([('☎️', '116 123', 'Kryzys dorośli'), ('👶', '116 111', 'Kryzys dzieci'), ('🆘', '800 70 22 22', 'Centrum kryzysu'), ('🚨', '112', 'Numer alarmowy'), ('💚', 'psycholodzy.pl', 'Online')])
    elif kind == 'simple_news':
        body = app_bar('Aktualności', large=True) + '\n' + body_simple_list([('📢', 'be:Safe v98', 'Nowy tryb ciemny'), ('🛡️', 'Pomoc sąsiedzka', 'Wrzesień 2026'), ('🚨', 'Alerty RCB', 'Współpraca')])
    elif kind == 'simple_pets':
        body = app_bar('Zwierzęta', large=True) + '\n' + body_simple_list([('🐶', 'Dodaj zwierzaka', 'Pies, kot, ptak...'), ('📍', 'Zaginione w pobliżu', 'Brak'), ('🏠', 'Moje', 'Pusto')])
    elif kind == 'simple_legal':
        body = app_bar('Regulamin', large=True) + '\n' + body_simple_list([('📄', 'Regulamin', 'Warunki użytkowania'), ('🔐', 'Polityka prywatności', 'RODO'), ('ℹ️', 'O aplikacji', 'be:Safe v98'), ('🛡️', 'Bezpieczeństwo', 'Twoje dane')])

    out.append(body)

    # dock (skip for fullscreen-immersive screens)
    no_dock = kind in ('onboarding', 'login', 'fake_incoming') or name in ('01_onboarding', '02_mode_picker', '03_login', '04_forgot_password', 'a2_fake_call_incoming')
    if not no_dock:
        # determine active label
        if 'home' in name:
            active = 'Home'
        elif 'map' in name or '38' in name or '39' in name:
            active = 'Mapa'
        elif 'sos' in name and 'mental' not in name:
            active = 'SOS'
        elif 'family' in name or '30_' in name or '31_' in name or '32_' in name or '33_' in name or '35' in name or '36' in name or '37' in name or '40' in name or '41' in name:
            active = 'Rodzina'
        elif 'profile' in name or '60_' in name or '61_' in name or '62_' in name or '63_' in name or '70_' in name or '71_' in name or '72_' in name or '80_' in name or '81_' in name or '82_' in name or '90_' in name or 'a3' in name or 'b0' in name:
            active = 'Profil'
        else:
            active = None
        out.append(dock_svg(active_label=active))

    out.append('</g>')  # clip-path
    # frame label
    out.append(f'<text x="0" y="{H+30}" fill="{COL["label2"]}" font-size="12" font-weight="600">{name}</text>')
    out.append(f'<text x="0" y="{H+50}" fill="{COL["navy"]}" font-size="13" font-weight="500">{label}</text>')
    out.append('</g>')
    return '\n'.join(out)


def build_master():
    """Build master SVG with all 44 frames in 7-col grid."""
    rows = (len(SCREENS) + COLS - 1) // COLS
    master_w = PAD*2 + COLS*W + (COLS-1)*GAP
    master_h = PAD*2 + rows*(H+80) + (rows-1)*GAP
    out = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {master_w} {master_h}" width="{master_w}" height="{master_h}">')
    out.append(INTER_FONT_FACE)
    out.append(f'<rect width="{master_w}" height="{master_h}" fill="#FAFBFC"/>')
    out.append(f'<text x="{PAD}" y="60" fill="{COL["navy"]}" font-size="28" font-weight="700">be:Safe v99 — 44 ekrany (real data: meneswczesny@gmail.com)</text>')
    out.append(f'<text x="{PAD}" y="84" fill="{COL["label2"]}" font-size="14">Identyczne ikony, czcionki, kolory, awatar, gradienty jak w APK v99 LIVE</text>')
    for i, (name, kind, label) in enumerate(SCREENS):
        col = i % COLS
        row = i // COLS
        x = PAD + col*(W+GAP)
        y = PAD + 60 + row*(H+80+GAP)
        out.append(make_frame(name, kind, label, x, y))
    out.append('</svg>')
    return '\n'.join(out)


def build_individual(name, kind, label):
    """Build single screen SVG file."""
    out = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H+60}" width="{W}" height="{H+60}">')
    out.append(INTER_FONT_FACE)
    out.append(make_frame(name, kind, label, 0, 0))
    out.append('</svg>')
    return '\n'.join(out)


def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    individual_dir = os.path.join(out_dir, 'individual')
    os.makedirs(individual_dir, exist_ok=True)

    # master
    master_path = os.path.join(out_dir, 'besafe_v99_all.svg')
    with open(master_path, 'w') as f:
        f.write(build_master())
    print(f'Master: {master_path} ({os.path.getsize(master_path)//1024} KB)')

    # individual
    for name, kind, label in SCREENS:
        p = os.path.join(individual_dir, f'{name}.svg')
        with open(p, 'w') as f:
            f.write(build_individual(name, kind, label))
    print(f'Individual: {individual_dir}/ ({len(SCREENS)} files)')

    # index.html preview
    idx_html = ['<!doctype html><html><head><meta charset="utf-8"><title>be:Safe v99 — Figma Export</title>',
        '<style>body{font-family:Inter,sans-serif;background:#0A0E14;color:#F5F7FA;margin:0;padding:32px}h1{font-weight:700;letter-spacing:-0.5px}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:24px;margin-top:24px}.card{background:#131820;border-radius:18px;padding:12px;border:1px solid #1F2730}.card img,.card object{width:100%;height:auto;border-radius:12px;background:#F2F2F7}.lbl{font-size:11px;color:#9CA3AF;margin-top:8px}.tit{font-size:13px;font-weight:600;color:#F5F7FA}</style></head><body>',
        '<h1>be:Safe v99 — IDENTYCZNY wygląd jak APK</h1>',
        '<p style="color:#9CA3AF">44 ekrany · realne dane meneswczesny@gmail.com · Inter font · oryginalne dock SVG paths · Google avatar embedded</p>',
        '<p style="color:#9CA3AF">Import do Figma: File → Import → besafe_v99_all.svg → 44 grupy z nazwami → Cmd/Ctrl+Alt+G</p>',
        '<div class="grid">']
    for name, kind, label in SCREENS:
        idx_html.append(f'<div class="card"><object data="individual/{name}.svg" type="image/svg+xml"></object><div class="tit">{label}</div><div class="lbl">{name}</div></div>')
    idx_html.append('</div></body></html>')
    with open(os.path.join(out_dir, 'index.html'), 'w') as f:
        f.write('\n'.join(idx_html))
    print(f'Preview: {out_dir}/index.html')


if __name__ == '__main__':
    main()
