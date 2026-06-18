#!/usr/bin/env python3
"""
Scalability comparison: 8x8, 16x16, 20x20 Booth multipliers.

Collects:
  - Area from syn/reports/area_*.rpt
  - Power (gauss_fast, total) from pwr/reports/power_*gauss_fast*.rpt
  - Accuracy (gauss NMED, SNR) from compute_accuracy_multi results (hardcoded)

Run from: py/
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

# ── Accuracy (gauss, 1M samples) ─────────────────────────────────────────────
# Values from compute_accuracy_multi.py run
ACCURACY = {
    # (width, mode): (NMED, MRED, SNR_dB)
    (8,  'exact'):    (0,        0,        float('inf')),
    (8,  'approx_1'): (3.31e-4,  3.57e-2,  28.66),
    (8,  'approx_2'): (1.55e-3,  7.21e-2,  15.68),
    (16, 'exact'):    (0,        0,        float('inf')),
    (16, 'approx_1'): (1.30e-6,  3.77e-4,  76.65),
    (16, 'approx_2'): (2.19e-5,  4.42e-3,  52.27),
    (16, 'approx_3'): (3.53e-4,  3.84e-2,  28.14),
    (16, 'approx_4'): (1.54e-3,  7.33e-2,  15.64),
    (20, 'exact'):    (0,        0,        float('inf')),
    (20, 'approx_1'): (8.30e-8,  2.98e-5,  100.98),
    (20, 'approx_2'): (1.41e-6,  3.89e-4,  76.53),
    (20, 'approx_3'): (2.26e-5,  4.35e-3,  52.42),
    (20, 'approx_4'): (3.61e-4,  3.78e-2,  28.37),
}

# ── Area ─────────────────────────────────────────────────────────────────────
AREA_RE = re.compile(r"Chip area for module.*?:\s*([\d.]+)")

def read_area(rpt_path):
    try:
        text = Path(rpt_path).read_text()
        m = AREA_RE.search(text)
        return float(m.group(1)) if m else None
    except FileNotFoundError:
        return None

AREA = {}
for w, tag in [(8, '8'), (16, ''), (20, '20')]:
    suffix = f'_{tag}' if tag else ''
    AREA[(w, 'booth')]   = read_area(ROOT / f'syn/reports/area_mult_booth{suffix}.rpt')
    AREA[(w, 'extrec')]  = read_area(ROOT / f'syn/reports/area_mult_booth_extrec{suffix}.rpt')

# ── Power ─────────────────────────────────────────────────────────────────────
PWR_RE = re.compile(r"^Total\s+([\d.e+\-]+)\s+([\d.e+\-]+)\s+([\d.e+\-]+)\s+([\d.e+\-]+)",
                    re.MULTILINE)

def read_power(rpt_path):
    try:
        text = Path(rpt_path).read_text()
        m = PWR_RE.search(text)
        return float(m.group(4)) if m else None   # column 4 = total power
    except FileNotFoundError:
        return None

SCENARIOS = ["gauss_fast", "gauss_slow"]
PWR = {}
for w, tag in [(8, '8'), (16, ''), (20, '20')]:
    for scn in SCENARIOS:
        key_booth = (w, 'booth', scn)
        PWR[key_booth] = read_power(
            ROOT / f'pwr/reports/power_booth{tag}_{scn}.rpt'
            if tag else ROOT / f'pwr/reports/power_booth_{scn}.rpt')
        for mode in ['standard', 'exact', 'approx_1', 'approx_2']:
            PWR[(w, mode, scn)] = read_power(
                ROOT / f'pwr/reports/power_booth_extrec{tag}_{scn}_{mode}.rpt'
                if tag else ROOT / f'pwr/reports/power_booth_extrec_{scn}_{mode}.rpt')

def fmt(v, unit='', fmt='.3e'):
    if v is None:
        return '-'
    if v == float('inf'):
        return 'inf'
    return f'{v:{fmt}}{unit}'

def pct(v, ref):
    if v is None or ref is None or ref == 0:
        return '-'
    return f'{(v - ref) / ref * 100:+.1f}%'

# ── Print ──────────────────────────────────────────────────────────────────────
SEP = '─' * 100

print()
print("╔══ AREA (µm², NanGate45) ══════════════════════════════════════════════════╗")
print(f"  {'Width':>6}  {'booth':>12}  {'extrec':>12}  {'overhead':>10}")
print(f"  {'─'*6}  {'─'*12}  {'─'*12}  {'─'*10}")
for w in [8, 16, 20]:
    b = AREA.get((w, 'booth'))
    e = AREA.get((w, 'extrec'))
    print(f"  {w:>4}×{w:<2}  {fmt(b,'', '.1f'):>12}  {fmt(e,'', '.1f'):>12}  {pct(e,b):>10}")

print()
print("╔══ ACCURACY (gauss, 1M samples) ═══════════════════════════════════════════╗")
print(f"  {'Width':>6}  {'mode':>10}  {'NMED':>12}  {'MRED':>12}  {'SNR, дБ':>10}")
print(f"  {'─'*6}  {'─'*10}  {'─'*12}  {'─'*12}  {'─'*10}")
for w in [8, 16, 20]:
    modes = ['exact', 'approx_1', 'approx_2'] if w == 8 else \
            ['exact', 'approx_1', 'approx_2', 'approx_3', 'approx_4']
    for mode in modes:
        acc = ACCURACY.get((w, mode))
        if acc:
            nmed, mred, snr = acc
            snr_s = 'inf' if snr == float('inf') else f'{snr:.2f}'
            print(f"  {w:>4}×{w:<2}  {mode:>10}  {fmt(nmed):>12}  {fmt(mred):>12}  {snr_s:>10}")
    print(f"  {'─'*6}  {'─'*10}  {'─'*12}  {'─'*12}  {'─'*10}")

# "vs booth"    — относительно mult_booth (другая архитектура: внутренний
#                 рекодер + узкая шина a). Загрязнён overhead'ом вынесенной
#                 широкой шины a_recoded, поэтому НЕ фигура эффекта перекодировки.
# "vs standard" — относительно extrec в passthrough (та же архитектура, нулей
#                 не добавляет). Изолирует именно вклад зануления строк PPG.
for scn in SCENARIOS:
    print()
    print(f"╔══ POWER ({scn}, total, Вт) {'═'*(43-len(scn))}╗")
    print(f"  {'Width':>6}  {'config':>22}  {'power, Вт':>12}  {'vs booth':>10}  {'vs standard':>12}")
    print(f"  {'─'*6}  {'─'*22}  {'─'*12}  {'─'*10}  {'─'*12}")
    for w in [8, 16, 20]:
        ref_b = PWR.get((w, 'booth', scn))      # архитектурная нижняя граница (справочно)
        ref_s = PWR.get((w, 'standard', scn))   # база эффекта перекодировки
        print(f"  {w:>4}×{w:<2}  {'booth (ref)':>22}  {fmt(ref_b):>12}  {'—':>10}  {pct(ref_b, ref_s):>12}")
        for mode in ['standard', 'exact', 'approx_1', 'approx_2']:
            v = PWR.get((w, mode, scn))
            vs_std = '—' if mode == 'standard' else pct(v, ref_s)
            print(f"  {w:>4}×{w:<2}  {f'extrec_{mode}':>22}  {fmt(v):>12}  {pct(v, ref_b):>10}  {vs_std:>12}")
        print(f"  {'─'*6}  {'─'*22}  {'─'*12}  {'─'*10}  {'─'*12}")
