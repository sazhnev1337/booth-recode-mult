#!/usr/bin/env python3
"""
Графики метрик точности (NMED, MRED, SNR) в зависимости от approx-level.
Кривые для uniform и gauss распределений.
"""

import math
import random
import matplotlib.pyplot as plt
import numpy as np
from booth_recoder import recode

from pathlib import Path
FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

N_SAMPLES = 1_000_000
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


def reconstruct_product(digits, b):
    total = 0
    for i, (n, o, t) in enumerate(digits):
        if t:
            magnitude = 2
        elif o:
            magnitude = 1
        else:
            magnitude = 0
        if n:
            magnitude = -magnitude
        total += magnitude * b * (1 << (2 * i))
    return total


def compute_metrics(distribution, mode, n_samples):
    rng = random.Random(SEED)
    sum_ed = 0
    sum_red = 0.0
    n_red_terms = 0
    sum_signal_sq = 0
    sum_noise_sq = 0
    max_out = 1 << (2 * 16 - 1)

    for _ in range(n_samples):
        a = sample(distribution, rng)
        b = sample(distribution, rng)
        digits = recode(a, mode)
        p_approx = reconstruct_product(digits, b)
        p_exact = a * b
        err = p_approx - p_exact
        ed = abs(err)
        sum_ed += ed
        sum_signal_sq += p_exact * p_exact
        sum_noise_sq += err * err
        if p_exact != 0:
            sum_red += ed / abs(p_exact)
            n_red_terms += 1

    nmed = sum_ed / n_samples / max_out
    mred = sum_red / n_red_terms
    snr_db = 10.0 * math.log10(sum_signal_sq / sum_noise_sq) if sum_noise_sq > 0 else float('inf')
    return nmed, mred, snr_db


def main():
    modes = ['exact', 'approx_1', 'approx_2', 'approx_3', 'approx_4']
    x_labels = ['exact', 'approx_1', 'approx_2', 'approx_3', 'approx_4']
    x_pos = np.arange(len(modes))

    distributions = ['uniform', 'gauss']
    colors = {'uniform': '#1f77b4', 'gauss': '#ff7f0e'}

    nmed_data = {d: [] for d in distributions}
    mred_data = {d: [] for d in distributions}
    snr_data  = {d: [] for d in distributions}

    for distr in distributions:
        print(f"Computing for {distr}...")
        for mode in modes:
            nmed, mred, snr = compute_metrics(distr, mode, N_SAMPLES)
            nmed_data[distr].append(nmed)
            mred_data[distr].append(mred)
            snr_data[distr].append(snr)
            print(f"  {mode}: NMED={nmed:.3e}  MRED={mred:.3e}  SNR={snr:.2f} dB")

    fig, axes = plt.subplots(1, 3, figsize=(16, 5))

    # NMED
    ax = axes[0]
    for distr in distributions:
        # Заменяем 0 на nan, чтобы log-scale не падал (для exact NMED=0).
        y = [v if v > 0 else float('nan') for v in nmed_data[distr]]
        ax.plot(x_pos, y, marker='o', label=distr, color=colors[distr], linewidth=2)
    ax.set_yscale('log')
    ax.set_xticks(x_pos)
    ax.set_xticklabels(x_labels, rotation=15)
    ax.set_ylabel('NMED')
    ax.set_title('Normalized Mean Error Distance')
    ax.grid(True, which='both', alpha=0.3)
    ax.legend()

    # MRED
    ax = axes[1]
    for distr in distributions:
        y = [v if v > 0 else float('nan') for v in mred_data[distr]]
        ax.plot(x_pos, y, marker='o', label=distr, color=colors[distr], linewidth=2)
    ax.set_yscale('log')
    ax.set_xticks(x_pos)
    ax.set_xticklabels(x_labels, rotation=15)
    ax.set_ylabel('MRED')
    ax.set_title('Mean Relative Error Distance')
    ax.grid(True, which='both', alpha=0.3)
    ax.legend()

    # SNR
    ax = axes[2]
    for distr in distributions:
        # Для exact SNR = inf, заменим на nan, чтобы не ломать график.
        y = [v if math.isfinite(v) else float('nan') for v in snr_data[distr]]
        ax.plot(x_pos, y, marker='o', label=distr, color=colors[distr], linewidth=2)
    ax.set_xticks(x_pos)
    ax.set_xticklabels(x_labels, rotation=15)
    ax.set_ylabel('SNR (dB)')
    ax.set_title('Signal-to-Noise Ratio')
    ax.grid(True, alpha=0.3)
    ax.legend()

    fig.suptitle('Accuracy metrics by recoding mode', fontsize=14)
    plt.tight_layout()
    out = FIGURES_DIR / "accuracy_nmed_mred_snr.png"
    plt.savefig(out, dpi=120, bbox_inches='tight')
    print(f"\nSaved: {out}")
    plt.show()


if __name__ == "__main__":
    main()
