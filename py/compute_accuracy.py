#!/usr/bin/env python3
"""
Вычисление метрик точности для booth-recoder.

Метрики:
    NMED   — Normalized Mean Error Distance
    MRED   — Mean Relative Error Distance
    SNR    — Signal-to-Noise Ratio, в дБ
    Bias   — систематическое смещение (mean error со знаком)
    Bias%  — относительное смещение к среднему |p_exact|
    MaxED  — максимальное абсолютное отклонение
"""

import math
import random
from booth_recoder import recode


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
    sum_ed_signed = 0           # для bias
    sum_red = 0.0
    n_red_terms = 0
    sum_p_exact_abs = 0         # для относительного bias
    sum_signal_sq = 0           # для SNR — энергия сигнала
    sum_noise_sq = 0            # для SNR — энергия шума
    max_ed = 0

    max_out = 1 << (2 * 16 - 1)  # 2^31 для NMED

    for _ in range(n_samples):
        a = sample(distribution, rng)
        b = sample(distribution, rng)

        digits = recode(a, mode)
        p_approx = reconstruct_product(digits, b)
        p_exact = a * b

        err = p_approx - p_exact
        ed = abs(err)

        sum_ed += ed
        sum_ed_signed += err
        sum_p_exact_abs += abs(p_exact)
        sum_signal_sq += p_exact * p_exact
        sum_noise_sq += err * err

        if ed > max_ed:
            max_ed = ed

        if p_exact != 0:
            sum_red += ed / abs(p_exact)
            n_red_terms += 1

    nmed = sum_ed / n_samples / max_out
    mred = sum_red / n_red_terms if n_red_terms > 0 else 0.0
    bias = sum_ed_signed / n_samples
    mean_abs_exact = sum_p_exact_abs / n_samples
    bias_rel = bias / mean_abs_exact if mean_abs_exact > 0 else 0.0

    if sum_noise_sq > 0:
        snr_db = 10.0 * math.log10(sum_signal_sq / sum_noise_sq)
        snr_str = f"{snr_db:>9.2f}"
    else:
        snr_str = f"{'inf':>9}"

    return {
        "nmed": nmed,
        "mred": mred,
        "snr": snr_str,
        "bias": bias,
        "bias_rel": bias_rel,
        "max_ed": max_ed,
    }


def main():
    distributions = ["uniform", "gauss"]
    modes = ["standard", "exact", "approx_1", "approx_2", "approx_3", "approx_4"]

    print(f"{'distr':>8} {'mode':>10} {'NMED':>12} {'MRED':>12} {'SNR_dB':>10} "
          f"{'bias':>12} {'bias_%':>10} {'maxED':>10}")
    print("-" * 96)

    for distr in distributions:
        for mode in modes:
            m = compute_metrics(distr, mode, N_SAMPLES)
            print(f"{distr:>8} {mode:>10} "
                  f"{m['nmed']:>12.3e} {m['mred']:>12.3e} {m['snr']:>10} "
                  f"{m['bias']:>12.3e} {m['bias_rel']*100:>9.4f}% {m['max_ed']:>10d}")


if __name__ == "__main__":
    main()
