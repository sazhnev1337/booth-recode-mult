#!/usr/bin/env python3
"""
Stimulus generator for 20-bit multipliers.

Usage:
    gen_stimulus_20.py <distribution> <update_period> <recoding_mode> <output_path> [N]

Examples:
    gen_stimulus_20.py uniform 1   standard ../sim/data/stim20_uniform_fast_standard.txt 20000
    gen_stimulus_20.py gauss   10  approx_2 ../sim/data/stim20_gauss_slow_approx_2.txt
"""

import sys
import random
from booth_recoder_generic import recode_w, digits_to_vec

WIDTH  = 20
SIGMA  = 131072
SEED   = 0xDEADBEEF
LO, HI = -(1 << (WIDTH - 1)), (1 << (WIDTH - 1)) - 1


def sample(distribution, rng):
    if distribution == "uniform":
        return rng.randint(LO, HI)
    elif distribution == "gauss":
        x = int(rng.gauss(0, SIGMA))
        return max(LO, min(HI, x))
    else:
        raise ValueError(f"unknown distribution: {distribution}")


def main():
    if len(sys.argv) not in (5, 6):
        print(__doc__)
        sys.exit(1)

    distribution  = sys.argv[1]
    update_period = int(sys.argv[2])
    mode          = sys.argv[3]
    out_path      = sys.argv[4]
    N             = int(sys.argv[5]) if len(sys.argv) == 6 else 100000

    rng = random.Random(SEED)
    a_cur = sample(distribution, rng)
    vec_cur = digits_to_vec(recode_w(a_cur, mode, WIDTH), WIDTH)

    with open(out_path, "w") as f:
        for i in range(N):
            if i > 0 and i % update_period == 0:
                a_cur   = sample(distribution, rng)
                vec_cur = digits_to_vec(recode_w(a_cur, mode, WIDTH), WIDTH)
            b = sample(distribution, rng)
            f.write(f"{a_cur}\n{b}\n{vec_cur}\n")

    print(f"Generated {N} samples (width={WIDTH}, {distribution}, "
          f"period={update_period}, mode={mode}) -> {out_path}")


if __name__ == "__main__":
    main()
