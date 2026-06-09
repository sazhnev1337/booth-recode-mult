#!/usr/bin/env python3
"""
Вычисление NMED, MRED  для booth-recoder'а в режимах standard/exact/approx_*.

Для каждого режима генерируем N пар (a, b), вычисляем:
    p_exact   = a * b
    p_approx  = результат умножения через recoded-цепочку (как в Verilog-DUT)
И считаем метрики.

Usage:
    python3 compute_accuracy.py
"""

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
    """
    По набору 8 троек (neg, one, two) восстанавливаем то, что выдал бы умножитель.
    Эквивалентно обратному преобразованию Booth-цифр + знак.
    """
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
    max_ed = 0
    n_zero_error = 0

    max_out = 1 << (2 * 16 - 1)  # 2^31

    for _ in range(n_samples):
        a = sample(distribution, rng)
        b = sample(distribution, rng)

        digits = recode(a, mode)
        p_approx = reconstruct_product(digits, b)
        p_exact = a * b

        ed = abs(p_approx - p_exact)
        sum_ed += ed
        if ed > max_ed:
            max_ed = ed
        if ed == 0:
            n_zero_error += 1

        if p_exact != 0:
            red = ed / abs(p_exact)
            sum_red += red
            n_red_terms += 1
        else:
            # ED при p_exact=0: если ED тоже 0, считаем как PRED.
            pass

    nmed = sum_ed / n_samples / max_out
    mred = sum_red / n_red_terms if n_red_terms > 0 else 0.0
    pct_zero = n_zero_error / n_samples * 100

    return {
        "nmed": nmed,
        "mred": mred,
        "max_ed": max_ed,
        "pct_zero_error": pct_zero,
    }


def main():
    distributions = ["uniform", "gauss"]
    modes = ["standard", "exact", "approx_1", "approx_2"]

    print(f"{'distr':>8} {'mode':>10} {'NMED':>12} {'MRED':>12} {'max ED':>12} {'zero err%':>10}")
    print("-" * 80)

    for distr in distributions:
        for mode in modes:
            m = compute_metrics(distr, mode, N_SAMPLES)
            print(f"{distr:>8} {mode:>10} {m['nmed']:>12.3e} {m['mred']:>12.3e} "
                  f"{m['max_ed']:>12d} {m['pct_zero_error']:>10.2f}")


if __name__ == "__main__":
    main()
