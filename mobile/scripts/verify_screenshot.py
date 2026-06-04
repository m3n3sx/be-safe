#!/usr/bin/env python3
"""be:Safe — pikselowy weryfikator zrzutów ekranu (visual regression).

Po co: wbudowane narzędzia do "oglądania" zrzutów bywają zawodne, a do testów
wizualnych (różne density/font/proporcje) potrzeba DETERMINISTYCZNYCH asercji.
Ten skrypt analizuje PNG ze `adb exec-out screencap -p` programowo (PIL) i
sprawdza konkretne właściwości bez polegania na wzroku.

Wymaga: Pillow (`pip install pillow`).

Sprawdzenia:
  fab   — obecność czerwonego FAB "Zgłoś" (#FF4848) w prawym-dolnym regionie.
          Po v115 FAB jest TYLKO na Home.
  topbar-clip — czy najbardziej prawa ciemna ikona w pasie topbara nie dotyka
          prawej krawędzi (obcięcie przy dużym density).

Przykłady:
  python3 verify_screenshot.py home.png fab --expect 1
  python3 verify_screenshot.py family.png fab --expect 0
  python3 verify_screenshot.py family.png topbar-clip
"""
import sys
import argparse
from PIL import Image

FAB_RGB = (255, 72, 72)  # Figma node 2050:33 #FF4848
FAB_TOL = 40


def _close(c, t, tol):
    return all(abs(c[i] - t[i]) <= tol for i in range(3))


def check_fab(im):
    """Zwraca (has_fab, ratio). Skanuje prawy-dolny róg nad dockiem."""
    w, h = im.size
    px = im.load()
    x0, y0, y1 = int(w * 0.62), int(h * 0.60), int(h * 0.92)
    hits = total = 0
    step = max(1, (w - x0) // 120)
    for y in range(y0, y1, step):
        for x in range(x0, w, step):
            total += 1
            if _close(px[x, y], FAB_RGB, FAB_TOL):
                hits += 1
    ratio = hits / max(total, 1)
    return ratio > 0.015, round(ratio, 4)


def check_topbar_clip(im, dark_thr=120):
    """Zwraca (clipped, rightmost_pct). Szuka rzędu ikon w górnych ~7-16% i
    sprawdza, czy najbardziej prawa ciemna ikona nie dotyka krawędzi (>98%)."""
    w, h = im.size
    px = im.load()
    # znajdź rząd o najwięcej ciemnych pikseli w pasie 6-18% wys.
    best_y, best_c = 0, -1
    for y in range(int(h * 0.06), int(h * 0.18), 4):
        c = sum(1 for x in range(0, w, 3)
                if all(v < dark_thr for v in px[x, y]))
        if c > best_c:
            best_c, best_y = c, y
    rightmost = 0
    for x in range(w - 1, int(w * 0.5), -1):
        if all(v < dark_thr for v in px[x, best_y]):
            rightmost = x
            break
    pct = round(rightmost / w * 100, 1)
    return rightmost >= w - 3, pct


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("check", choices=["fab", "topbar-clip"])
    ap.add_argument("--expect", type=int, choices=[0, 1], default=None)
    a = ap.parse_args()
    im = Image.open(a.image).convert("RGB")

    if a.check == "fab":
        has, ratio = check_fab(im)
        line = f"{a.image}: fab={int(has)} ratio={ratio}"
        if a.expect is not None:
            ok = int(has) == a.expect
            line += f" expect={a.expect} -> {'PASS' if ok else 'FAIL'}"
            print(line)
            sys.exit(0 if ok else 1)
        print(line)
    else:
        clipped, pct = check_topbar_clip(im)
        print(f"{a.image}: topbar_rightmost={pct}% clipped={int(clipped)} "
              f"-> {'FAIL' if clipped else 'PASS'}")
        sys.exit(1 if clipped else 0)


if __name__ == "__main__":
    main()
