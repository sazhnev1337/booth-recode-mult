#!/usr/bin/env python3
import random

random.seed(0xDEADBEEF)
N = 10000

with open('../sim/data/stimulus.txt', 'w') as f:
    for _ in range(N):
        a = random.randint(-32768, 32767)
        b = random.randint(-32768, 32767)
        f.write(f"{a}\n{b}\n")

print(f"Generated {N} pairs -> sim/data/stimulus.txt")