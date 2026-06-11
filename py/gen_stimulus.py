#!/usr/bin/env python3
"""
Генерация stimulus-файла для умножителей с внешним recoder.

Формат файла: три значения на пару (по строке каждое):
    a_value_signed
    b_value_signed
    recoded_24bit_unsigned

Usage:
    gen_stimulus.py <distribution> <update_period> <recoding_mode> <output_path>

Examples:
    gen_stimulus.py uniform 1   standard  ../sim/data/stim_uniform_fast_standard.txt
    gen_stimulus.py gauss   50  exact     ../sim/data/stim_gauss_slow_exact.txt
    gen_stimulus.py gauss   50  approx_2  ../sim/data/stim_gauss_slow_approx_2.txt
"""

import sys
import random
from booth_recoder import recode, digits_to_24bit

SIGMA = 8000
SEED = 0xDEADBEEF


def sample(distribution, rng):
    if distribution == "uniform":
        return rng.randint(-32768, 32767)
    elif distribution == "gauss":
        x = int(rng.gauss(0, SIGMA))
        return max(-32768, min(32767, x))
    else:
        raise ValueError(f"unknown distribution: {distribution}")


def main():
    if len(sys.argv) not in (5, 6):
        print(__doc__)
        sys.exit(1)

    distribution = sys.argv[1]
    update_period = int(sys.argv[2])
    recoding_mode = sys.argv[3]
    out_path = sys.argv[4]
    N = int(sys.argv[5]) if len(sys.argv) == 6 else 100000

    rng = random.Random(SEED)
    a_current = sample(distribution, rng)
    a_recoded_current = digits_to_24bit(recode(a_current, recoding_mode))

    with open(out_path, "w") as f:
        for i in range(N):
            if i > 0 and i % update_period == 0:
                a_current = sample(distribution, rng)
                a_recoded_current = digits_to_24bit(recode(a_current, recoding_mode))
            b = sample(distribution, rng)
            f.write(f"{a_current}\n{b}\n{a_recoded_current}\n")

    print(f"Generated {N} samples ({distribution}, period={update_period}, mode={recoding_mode}) -> {out_path}")


if __name__ == "__main__":
    main()
