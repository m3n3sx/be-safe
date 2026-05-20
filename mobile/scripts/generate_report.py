#!/usr/bin/env python3
"""Generate HTML report from E2E test metrics JSON files.

Usage: generate_report.py <metrics_dir> [output.html]
"""
import json
import sys
from pathlib import Path
from datetime import datetime
from collections import defaultdict

if len(sys.argv) < 2:
    print("Usage: generate_report.py <metrics_dir> [output.html]")
    sys.exit(1)

metrics_dir = Path(sys.argv[1])
output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else metrics_dir / "report.html"

# Load all JSON files
runs = []
for f in sorted(metrics_dir.glob("*.json")):
    try:
        data = json.loads(f.read_text())
        if "metrics" in data and data["metrics"]:
            runs.append({"file": f.name, "data": data})
    except Exception as e:
        print(f"skip {f}: {e}")

# Aggregate: persona -> suite -> list of metrics
by_persona = defaultdict(lambda: defaultdict(list))
for run in runs:
    for key, entries in run["data"]["metrics"].items():
        persona, suite = key.split("__", 1)
        by_persona[persona][suite].extend(entries)

def fmt_ms(v):
    if v is None: return "-"
    return f"{v} ms" if v < 1000 else f"{v/1000:.1f} s"

def status_icon(passed):
    if passed is None: return "📊"
    return "✅" if passed else "⚠️"

def row_color(passed):
    if passed is None: return "#f0f0f0"
    return "#d4edda" if passed else "#f8d7da"

html = ["""<!DOCTYPE html>
<html lang="pl">
<head>
<meta charset="utf-8">
<title>be:Safe E2E Test Report</title>
<style>
body { font-family: -apple-system, sans-serif; max-width: 1200px; margin: 20px auto; padding: 0 20px; color: #1a2027; }
h1 { color: #1a2027; border-bottom: 3px solid #9df4cb; padding-bottom: 10px; }
h2 { color: #1a2027; margin-top: 40px; }
h3 { color: #44474b; margin-top: 25px; }
.summary { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin: 20px 0; }
.card { background: #fcf8f9; border-radius: 12px; padding: 16px; border: 1px solid #c5c6cb; }
.card .label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.05em; color: #44474b; }
.card .value { font-size: 24px; font-weight: 700; margin-top: 4px; }
.metric-table { width: 100%; border-collapse: collapse; margin: 10px 0; font-size: 14px; }
.metric-table th, .metric-table td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
.metric-table th { background: #1a2027; color: white; font-weight: 500; }
.metric-table tr:hover { background: #f9f9f9; }
.note { color: #44474b; font-style: italic; font-size: 12px; }
.persona-tag { display: inline-block; padding: 2px 10px; border-radius: 12px; font-size: 11px; font-weight: 600; }
.pt { background: #1a2027; color: white; }
.pe { background: #9df4cb; color: #1a2027; }
.ka { background: #9EEBEC; color: #1a2027; }
.sj { background: #FF7A7A; color: white; }
</style>
</head>
<body>
"""]

html.append(f"<h1>be:Safe E2E Test Report</h1>")
html.append(f"<p class='note'>Generated: {datetime.now().isoformat(timespec='seconds')} · Source: {metrics_dir.name}</p>")

# Summary stats
total_metrics = sum(len(e) for p in by_persona.values() for e in p.values())
total_passed = sum(1 for p in by_persona.values() for s in p.values() for e in s if e.get("passed") is True)
total_failed = sum(1 for p in by_persona.values() for s in p.values() for e in s if e.get("passed") is False)
total_neutral = total_metrics - total_passed - total_failed

html.append("<div class='summary'>")
html.append(f"<div class='card'><div class='label'>Persony</div><div class='value'>{len(by_persona)}</div></div>")
html.append(f"<div class='card'><div class='label'>Total metryki</div><div class='value'>{total_metrics}</div></div>")
html.append(f"<div class='card'><div class='label'>Passed</div><div class='value' style='color:#1B873A'>✅ {total_passed}</div></div>")
html.append(f"<div class='card'><div class='label'>Failed</div><div class='value' style='color:#BA1A1A'>⚠️ {total_failed}</div></div>")
html.append("</div>")

# Per-persona breakdown
persona_labels = {
    "parent_tech": ("Rodzic techniczny (P1)", "pt"),
    "parent_easy": ("Rodzic nietechniczny (P2)", "pe"),
    "kid_anna": ("Dziecko 10 lat (P3)", "ka"),
    "senior_jadwiga": ("Senior 68 lat (P4)", "sj"),
    "global": ("Global", "pt"),
}

# Key metrics comparison table (login_to_home, app_warm_start, reach_sos)
html.append("<h2>Kluczowe metryki UX (porównanie person)</h2>")
key_metrics = ["app_warm_start", "login_to_home", "open_map", "open_family", "reach_sos", "open_profile", "open_settings"]
html.append("<table class='metric-table'>")
html.append("<tr><th>Metryka</th>")
for p in ["parent_tech", "parent_easy", "kid_anna", "senior_jadwiga"]:
    label, _ = persona_labels.get(p, (p, ""))
    html.append(f"<th>{label}</th>")
html.append("</tr>")

for km in key_metrics:
    html.append(f"<tr><td><b>{km}</b></td>")
    for p in ["parent_tech", "parent_easy", "kid_anna", "senior_jadwiga"]:
        vals = []
        for suite_entries in by_persona.get(p, {}).values():
            for e in suite_entries:
                if e.get("name") == km and e.get("value") is not None:
                    vals.append(e)
        if vals:
            v = vals[0]
            icon = status_icon(v.get("passed"))
            html.append(f"<td>{icon} {fmt_ms(v['value'])}</td>")
        else:
            html.append("<td>-</td>")
    html.append("</tr>")
html.append("</table>")

# Detailed per-persona
for persona in sorted(by_persona.keys()):
    label, cls = persona_labels.get(persona, (persona, ""))
    html.append(f"<h2><span class='persona-tag {cls}'>{label}</span></h2>")

    for suite in sorted(by_persona[persona].keys()):
        html.append(f"<h3>{suite}</h3>")
        html.append("<table class='metric-table'>")
        html.append("<tr><th>Nazwa</th><th>Wartość</th><th>Budżet</th><th>Status</th><th>Nota</th></tr>")
        for e in by_persona[persona][suite]:
            name = e.get("name", "?")
            value = e.get("value")
            unit = e.get("unit", "")
            budget = e.get("budget_ms")
            passed = e.get("passed")
            note = e.get("note", "")
            value_txt = "-"
            if value is not None:
                if unit == "ms":
                    value_txt = fmt_ms(value)
                else:
                    value_txt = f"{value} {unit}"
            budget_txt = fmt_ms(budget) if budget else "-"
            html.append(f"<tr style='background:{row_color(passed)}'>")
            html.append(f"<td>{name}</td><td>{value_txt}</td><td>{budget_txt}</td><td>{status_icon(passed)}</td><td class='note'>{note}</td>")
            html.append("</tr>")
        html.append("</table>")

html.append("</body></html>")

output_path.write_text("\n".join(html))
print(f"✅ Report: {output_path}")
print(f"   Personas: {len(by_persona)}, Metrics: {total_metrics}, Pass: {total_passed}, Fail: {total_failed}")
