#!/usr/bin/env python3
"""
Масштабируемость на алгоритмическом уровне: среднее число строк матрицы PP,
ДОБАВЛЕННО обнуляемых перекодировкой (exact_recodes + approx_recodes, без
«естественных» нулей Бута), в зависимости от разрядности 8/16/20.

Показывает монотонность: с ростом разрядности метод обнуляет в среднем всё
больше строк. Gauss-распределение (канонический сценарий сравнения).

Запуск из: py/
"""

import random
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
from booth_recoder_generic import recode_w_with_stats

FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

N_SAMPLES = 100_000
SEED = 0xDEADBEEF
SIGMA = {8: 32, 16: 8000, 20: 131072}      # согласовано с plot_pattern_stats.py
WIDTHS = [8, 16, 20]
MODES = ["exact", "approx_1", "approx_2"]
LABELS = {"exact": "exact", "approx_1": "approx_1", "approx_2": "approx_2"}
COLORS = {"exact": "#10b981", "approx_1": "#f59e0b", "approx_2": "#ef4444"}


def sample(rng, width):
    lo, hi = -(1 << (width - 1)), (1 << (width - 1)) - 1
    return max(lo, min(hi, int(rng.gauss(0, SIGMA[width]))))


def added_zero_rows(mode, width):
    """Среднее число добавленных перекодировкой нулевых строк на операнд."""
    rng = random.Random(SEED)
    total = 0
    for _ in range(N_SAMPLES):
        a = sample(rng, width)
        _, st = recode_w_with_stats(a, mode, width)
        total += st["exact_recodes"] + st["approx_recodes"]
    return total / N_SAMPLES


x = np.array(WIDTHS)            # реальные значения N (8/16/20) на оси абсцисс
fig, ax = plt.subplots(figsize=(8, 5.5))
ymax = 0.0
for mode in MODES:
    ys = [added_zero_rows(mode, w) for w in WIDTHS]
    ymax = max(ymax, max(ys))
    ax.plot(x, ys, marker="o", linewidth=2, color=COLORS[mode], label=LABELS[mode])
    for xi, v in zip(x, ys):
        ax.annotate(f"{v:.2f}", (xi, v), textcoords="offset points",
                    xytext=(0, 9), ha="center", fontsize=10, color=COLORS[mode])
    print(f"{mode:>9}: " + "  ".join(f"{w}:{v:.3f}" for w, v in zip(WIDTHS, ys)))

ax.set_xticks(WIDTHS)
ax.set_xticklabels([f"{w}×{w}" for w in WIDTHS])
ax.set_xlim(min(WIDTHS) - 2, max(WIDTHS) + 2)
ax.set_xlabel("Разрядность N, бит")
ax.set_ylabel("Среднее число добавленных перекодировкой\nнулевых строк PP (на операнд)")
ax.set_title("Масштабируемость метода: добавленные нулевые строки PP (gauss)")
ax.grid(axis="y", alpha=0.3)
ax.legend(loc="upper left")
ax.set_ylim(0, ymax + 0.18)

plt.tight_layout()
out = FIGURES_DIR / "scaling_zero_rows.png"
plt.savefig(out, dpi=120, bbox_inches="tight")
print(f"Saved: {out}")
