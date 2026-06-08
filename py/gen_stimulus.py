#!/usr/bin/env python3
"""
Генерация файла стимулов для tb_power.
Параметры — распределение и период обновления коэффициента a.
Операнд b всегда меняется каждый такт.

Usage:
    python3 gen_stimulus.py <distribution> <update_period> <output_path>

Examples:
    python3 gen_stimulus.py uniform 1   ../sim/data/stimulus_uniform_fast.txt
    python3 gen_stimulus.py uniform 50  ../sim/data/stimulus_uniform_slow.txt
    python3 gen_stimulus.py gauss   50  ../sim/data/stimulus_gauss_slow.txt
"""

import sys
import random

N = 10000
SIGMA = 8000
SEED = 0xDEADBEEF


def sample(distribution, rng):
    if distribution == "uniform":
        return rng.randint(-32768, 32767)
    elif distribution == "gauss":
        x = int(rng.gauss(0, SIGMA))
        # клиппинг к диапазону signed16
        return max(-32768, min(32767, x))
    else:
        raise ValueError(f"unknown distribution: {distribution}")


def main():
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    distribution = sys.argv[1]
    update_period = int(sys.argv[2])
    out_path = sys.argv[3]

    rng = random.Random(SEED)

    a_current = sample(distribution, rng)
    with open(out_path, "w") as f:
        for i in range(N):
            # a обновляется раз в update_period тактов
            if i > 0 and i % update_period == 0:
                a_current = sample(distribution, rng)
            b = sample(distribution, rng)
            f.write(f"{a_current}\n{b}\n")

    print(f"Generated {N} pairs ({distribution}, update_period={update_period}) -> {out_path}")


if __name__ == "__main__":
    main()
