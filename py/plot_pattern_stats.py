#!/usr/bin/env python3
"""
Строит график среднего числа нулевых PP-строк в зависимости от режима recoding.
Стопка: natural zeros + exact recodes + approx recodes.
Отдельно для uniform и gauss распределений, для каждой разрядности (8/16/20).
"""

import random
import matplotlib.pyplot as plt
import numpy as np
from booth_recoder_generic import recode_w_with_stats

from pathlib import Path
FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

N_SAMPLES = 100_000
SEED = 0xDEADBEEF

# Согласовано с py/compute_accuracy_multi.py.
SIGMA = {8: 32, 16: 8000, 20: 131072}

# Имя файла для 16 бит сохранено как есть — на него ссылаются
# doc/main_text/main.tex и doc/results/results.tex.
OUTPUT_NAME = {8: "patterns_zero_rows_by_mode_8.png",
               16: "patterns_zero_rows_by_mode.png",
               20: "patterns_zero_rows_by_mode_20.png"}


def sample(distribution, rng, width):
    lo = -(1 << (width - 1))
    hi = (1 << (width - 1)) - 1
    if distribution == "uniform":
        return rng.randint(lo, hi)
    elif distribution == "gauss":
        x = int(rng.gauss(0, SIGMA[width]))
        return max(lo, min(hi, x))
    else:
        raise ValueError(distribution)


def collect_stats(distribution, mode, width, n_samples):
    rng = random.Random(SEED)
    total_natural = 0
    total_exact = 0
    total_approx = 0
    for _ in range(n_samples):
        a = sample(distribution, rng, width)
        _, stats = recode_w_with_stats(a, mode, width)
        total_natural += stats['natural_zeros']
        total_exact   += stats['exact_recodes']
        total_approx  += stats['approx_recodes']
    return (total_natural / n_samples,
            total_exact / n_samples,
            total_approx / n_samples)


def plot_distribution(ax, distribution, modes, width):
    natural_means = []
    exact_means = []
    approx_means = []
    for mode in modes:
        n, e, a = collect_stats(distribution, mode, width, N_SAMPLES)
        natural_means.append(n)
        exact_means.append(e)
        approx_means.append(a)

    x = np.arange(len(modes))
    bar_width = 0.6

    # Стопка снизу вверх: natural → exact → approx.
    ax.bar(x, natural_means, bar_width, label='Natural Booth zeros', color='#888888')
    ax.bar(x, exact_means, bar_width, bottom=natural_means,
           label='Exact recodes', color='#3b82f6')
    ax.bar(x, approx_means, bar_width,
           bottom=[n + e for n, e in zip(natural_means, exact_means)],
           label='Approx recodes', color='#ef4444')

    n_pairs = width // 2
    ax.set_xticks(x)
    ax.set_xticklabels(modes, rotation=20)
    ax.set_ylabel(f'Avg number of zero PP rows (per {width}-bit operand)')
    ax.set_title(f'{distribution.capitalize()} distribution')
    ax.set_ylim(0, n_pairs)
    ax.grid(axis='y', alpha=0.3)
    ax.legend(loc='upper left')

    return natural_means, exact_means, approx_means


def plot_width(width, modes):
    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    plot_distribution(axes[0], 'uniform', modes, width)
    gauss_stats = plot_distribution(axes[1], 'gauss', modes, width)

    fig.suptitle(f'Average zero rows in PP matrix by recoding mode ({width}×{width})',
                 fontsize=14)
    plt.tight_layout()
    out = FIGURES_DIR / OUTPUT_NAME[width]
    plt.savefig(out, dpi=120, bbox_inches='tight')
    print(f"Saved: {out}")
    plt.close(fig)

    return gauss_stats


def print_table(width, modes, gauss_stats):
    natural_means, exact_means, approx_means = gauss_stats
    totals = [n + e + a for n, e, a in zip(natural_means, exact_means, approx_means)]
    baseline = totals[modes.index('standard')]  # обычные нули Бута, без перекодировки

    title = f"{width}×{width}, gauss distribution"
    print(f"\n=== {title} ===")
    header = (f"{'mode':>10}  {'natural':>9}  {'exact':>7}  {'approx':>7}  "
              f"{'total':>7}  {'Δ vs standard':>14}")
    print(header)
    print('-' * len(header))
    for mode, n, e, a, t in zip(modes, natural_means, exact_means, approx_means, totals):
        delta_pct = (t - baseline) / baseline * 100
        print(f"{mode:>10}  {n:9.3f}  {e:7.3f}  {a:7.3f}  {t:7.3f}  {delta_pct:13.1f}%")


def main():
    modes = ['standard', 'exact', 'approx_1', 'approx_2', 'approx_3', 'approx_4']
    for width in (8, 16, 20):
        gauss_stats = plot_width(width, modes)
        print_table(width, modes, gauss_stats)


if __name__ == "__main__":
    main()
