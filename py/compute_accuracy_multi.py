#!/usr/bin/env python3
"""
Accuracy metrics for Booth recoder across multiple bit-widths (8, 16, 20).

Metrics: NMED, MRED, SNR (dB), Bias, MaxED
"""

import math
import random
from booth_recoder_generic import recode_w, algebraic_value_w

N_SAMPLES  = 1_000_000
SEED       = 0xDEADBEEF
WIDTHS     = [8, 16, 20]
MODES      = ["standard", "exact", "approx_1", "approx_2", "approx_3", "approx_4"]

# SIGMA chosen as range/4 to keep the same relative spread across widths.
# Exception: 16-bit keeps the original 8000 to match earlier results.
SIGMA = {8: 32, 16: 8000, 20: 131072}


def _sample_uniform(rng, width):
    lo = -(1 << (width - 1))
    hi = (1 << (width - 1)) - 1
    return rng.randint(lo, hi)


def _sample_gauss(rng, width):
    lo = -(1 << (width - 1))
    hi = (1 << (width - 1)) - 1
    x = int(rng.gauss(0, SIGMA[width]))
    return max(lo, min(hi, x))


def reconstruct(digits, b):
    total = 0
    for i, (n, o, t) in enumerate(digits):
        mag = 2 if t else (1 if o else 0)
        if n:
            mag = -mag
        total += mag * b * (1 << (2 * i))
    return total


def compute_metrics(distribution, mode, width, n_samples):
    rng = random.Random(SEED)
    sample = _sample_uniform if distribution == "uniform" else _sample_gauss

    max_out = 1 << (2 * width - 1)

    sum_ed = 0
    sum_ed_signed = 0
    sum_red = 0.0
    n_red = 0
    sum_abs_exact = 0
    sum_sq_sig = 0
    sum_sq_noise = 0
    max_ed = 0

    for _ in range(n_samples):
        a = sample(rng, width)
        b = sample(rng, width)

        digits = recode_w(a, mode, width)
        p_approx = reconstruct(digits, b)
        p_exact  = a * b

        err = p_approx - p_exact
        ed  = abs(err)

        sum_ed       += ed
        sum_ed_signed += err
        sum_abs_exact += abs(p_exact)
        sum_sq_sig   += p_exact ** 2
        sum_sq_noise += err ** 2
        if ed > max_ed:
            max_ed = ed
        if p_exact != 0:
            sum_red += ed / abs(p_exact)
            n_red   += 1

    nmed = sum_ed / n_samples / max_out
    mred = sum_red / n_red if n_red > 0 else 0.0
    bias = sum_ed_signed / n_samples
    mean_abs = sum_abs_exact / n_samples
    bias_rel = bias / mean_abs if mean_abs > 0 else 0.0
    snr_str = (f"{10*math.log10(sum_sq_sig/sum_sq_noise):>9.2f}"
               if sum_sq_noise > 0 else f"{'inf':>9}")

    return {"nmed": nmed, "mred": mred, "snr": snr_str,
            "bias": bias, "bias_rel": bias_rel, "max_ed": max_ed}


def main():
    hdr = (f"{'width':>5} {'distr':>8} {'mode':>10} "
           f"{'NMED':>12} {'MRED':>12} {'SNR_dB':>10} "
           f"{'bias':>12} {'bias_%':>10} {'maxED':>12}")
    sep = "-" * len(hdr)
    print(hdr)
    print(sep)

    for width in WIDTHS:
        for distr in ["uniform", "gauss"]:
            for mode in MODES:
                m = compute_metrics(distr, mode, width, N_SAMPLES)
                print(f"{width:>5} {distr:>8} {mode:>10} "
                      f"{m['nmed']:>12.3e} {m['mred']:>12.3e} {m['snr']:>10} "
                      f"{m['bias']:>12.3e} {m['bias_rel']*100:>9.4f}% {m['max_ed']:>12d}")
        print(sep)


if __name__ == "__main__":
    main()
