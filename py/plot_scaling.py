#!/usr/bin/env python3
"""
График масштабируемости по разрядности (8/16/20 бит).

Левая панель  — накладные расходы площади вынесенной архитектуры
                (extrec - booth)/booth, %.
Правая панель — экономия мощности относительно базового умножителя
                (booth - extrec)/booth, %, сценарий gauss_slow,
                режимы exact и approx_2.

Все числа читаются из syn/reports/ и pwr/reports/ (единый флоу синтеза R3).
Запуск из: py/
"""

import re
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

WIDTHS = [8, 16, 20]
ATAG = {8: "_8", 16: "", 20: "_20"}     # суффикс area-отчётов
PTAG = {8: "8", 16: "", 20: "20"}       # суффикс power-отчётов
SCN = "gauss_slow"


def area(path):
    m = re.search(r"Chip area for module.*?:\s*([\d.]+)", Path(path).read_text())
    return float(m.group(1))


def power(path):
    m = re.search(r"^Total\s+\S+\s+\S+\s+\S+\s+([\d.e+-]+)",
                  Path(path).read_text(), re.M)
    return float(m.group(1)) * 1e6  # µW


area_ovh, save_exact, save_approx2 = [], [], []
for w in WIDTHS:
    at, pt = ATAG[w], PTAG[w]
    bA = area(ROOT / f"syn/reports/area_mult_booth{at}.rpt")
    eA = area(ROOT / f"syn/reports/area_mult_booth_extrec{at}.rpt")
    area_ovh.append((eA - bA) / bA * 100)

    bP = power(ROOT / f"pwr/reports/power_booth{pt}_{SCN}.rpt")
    ex = power(ROOT / f"pwr/reports/power_booth_extrec{pt}_{SCN}_exact.rpt")
    a2 = power(ROOT / f"pwr/reports/power_booth_extrec{pt}_{SCN}_approx_2.rpt")
    save_exact.append((bP - ex) / bP * 100)
    save_approx2.append((bP - a2) / bP * 100)

x = np.array(WIDTHS)            # реальные значения N на оси абсцисс
labels = [f"{w}×{w}" for w in WIDTHS]
xlim = (min(WIDTHS) - 2, max(WIDTHS) + 2)

fig, (axL, axR) = plt.subplots(1, 2, figsize=(12, 5))

# ── Левая панель: накладные расходы площади ──────────────────────────
axL.axhline(0, color="black", linewidth=0.8)
axL.plot(x, area_ovh, marker="o", color="#3b82f6", linewidth=2)
for xi, v in zip(x, area_ovh):
    axL.annotate(f"{v:+.1f}%", (xi, v), textcoords="offset points",
                 xytext=(0, 11 if v >= 0 else -17), ha="center", fontsize=11)
axL.set_xticks(WIDTHS)
axL.set_xticklabels(labels)
axL.set_xlim(*xlim)
axL.set_xlabel("Разрядность N, бит")
axL.set_ylabel("Накладные расходы площади\n(extrec − booth) / booth, %")
axL.set_title("Площадь: overhead вынесенной архитектуры")
axL.grid(axis="y", alpha=0.3)
axL.set_ylim(min(area_ovh) - 2.0, max(area_ovh) + 2.0)

# ── Правая панель: экономия мощности ─────────────────────────────────
axR.axhline(0, color="black", linewidth=0.8)
axR.plot(x, save_exact, marker="s", color="#10b981", linewidth=2, label="exact")
axR.plot(x, save_approx2, marker="o", color="#ef4444", linewidth=2, label="approx_2")
for xi, v in zip(x, save_exact):
    axR.annotate(f"{v:+.1f}%", (xi, v), textcoords="offset points",
                 xytext=(0, -17), ha="center", fontsize=11, color="#10b981")
for xi, v in zip(x, save_approx2):
    axR.annotate(f"{v:+.1f}%", (xi, v), textcoords="offset points",
                 xytext=(0, 11), ha="center", fontsize=11, color="#ef4444")
axR.set_xticks(WIDTHS)
axR.set_xticklabels(labels)
axR.set_xlim(*xlim)
axR.set_xlabel("Разрядность N, бит")
axR.set_ylabel("Экономия мощности\n(booth − extrec) / booth, %")
axR.set_title("Мощность: экономия от перекодировки (gauss_slow)")
axR.grid(axis="y", alpha=0.3)
_allR = save_exact + save_approx2 + [0.0]
axR.set_ylim(min(_allR) - 1.8, max(_allR) + 1.8)
axR.legend(loc="upper left")

fig.suptitle("Масштабируемость метода по разрядности умножителя", fontsize=14)
plt.tight_layout()
out = FIGURES_DIR / "scaling_area_power.png"
plt.savefig(out, dpi=120, bbox_inches="tight")
print(f"Saved: {out}")
print(f"area overhead: {[f'{v:+.1f}' for v in area_ovh]}")
print(f"save exact:    {[f'{v:+.1f}' for v in save_exact]}")
print(f"save approx_2: {[f'{v:+.1f}' for v in save_approx2]}")
