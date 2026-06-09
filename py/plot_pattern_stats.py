#!/usr/bin/env python3
"""
Строит график среднего числа нулевых PP-строк в зависимости от режима recoding.
Стопка: natural zeros + exact recodes + approx recodes.
Отдельно для uniform и gauss распределений.
"""

import random
import matplotlib.pyplot as plt
import numpy as np
from booth_recoder import recode_with_stats

from pathlib import Path
FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

N_SAMPLES = 100_000
SIGMA = 8000
SEED = 0xDEADBEEF


def sample(distribution, rng):
    if distribution == "uniform":
        return rng.randint(-32768, 32767)
    elif distribution == "gauss":
        x = int(rng.gauss(0, SIGMA))
        return max(-32768, min(32767, x))
    else:
        raise ValueError(distribution)


def collect_stats(distribution, mode, n_samples):
    rng = random.Random(SEED)
    total_natural = 0
    total_exact = 0
    total_approx = 0
    for _ in range(n_samples):
        a = sample(distribution, rng)
        _, stats = recode_with_stats(a, mode)
        total_natural += stats['natural_zeros']
        total_exact   += stats['exact_recodes']
        total_approx  += stats['approx_recodes']
    return (total_natural / n_samples,
            total_exact / n_samples,
            total_approx / n_samples)


def plot_distribution(ax, distribution, modes):
    natural_means = []
    exact_means = []
    approx_means = []
    for mode in modes:
        n, e, a = collect_stats(distribution, mode, N_SAMPLES)
        natural_means.append(n)
        exact_means.append(e)
        approx_means.append(a)

    x = np.arange(len(modes))
    width = 0.6

    # Стопка снизу вверх: natural → exact → approx.
    p1 = ax.bar(x, natural_means, width, label='Natural Booth zeros', color='#888888')
    p2 = ax.bar(x, exact_means, width, bottom=natural_means,
                label='Exact recodes', color='#3b82f6')
    p3 = ax.bar(x, approx_means, width,
                bottom=[n + e for n, e in zip(natural_means, exact_means)],
                label='Approx recodes', color='#ef4444')

    ax.set_xticks(x)
    ax.set_xticklabels(modes, rotation=20)
    ax.set_ylabel('Avg number of zero PP rows (per 16-bit operand)')
    ax.set_title(f'{distribution.capitalize()} distribution')
    ax.set_ylim(0, 8)
    ax.grid(axis='y', alpha=0.3)
    ax.legend(loc='upper left')


def main():
    modes = ['standard', 'exact', 'approx_1', 'approx_2', 'approx_3', 'approx_4']

    fig, axes = plt.subplots(1, 2, figsize=(14, 6))
    plot_distribution(axes[0], 'uniform', modes)
    plot_distribution(axes[1], 'gauss', modes)

    fig.suptitle('Average zero rows in PP matrix by recoding mode', fontsize=14)
    plt.tight_layout()
    out = FIGURES_DIR / "patterns_zero_rows_by_mode.png"
    plt.savefig(out, dpi=120, bbox_inches='tight')
    print(f"Saved: {out}")
    plt.show()


if __name__ == "__main__":
    main()
