#!/usr/bin/env python3
"""
Generic Booth recoder — supports any even bit-width.

recode_w(value, mode, width) -> list of n_pairs tuples (neg, one, two)
digits_to_vec(digits, width) -> int  (3*n_pairs bits: {two, one, neg})
algebraic_value_w(digits)    -> int  (reconstructed coefficient value)
"""


def _get_bit(value, k, width):
    """Bit k of a width-bit signed integer; sign-extends beyond MSB."""
    if k < 0:
        return 0
    if k >= width:
        return (value >> (width - 1)) & 1
    return (value >> k) & 1


def _booth_digit(a_high, a_mid, a_low):
    neg = a_high
    one = a_mid ^ a_low
    two = (a_high & (1 - a_mid) & (1 - a_low)) | ((1 - a_high) & a_mid & a_low)
    return (neg & 1, one & 1, two & 1)


def _get_window(value, i, width):
    """5-bit window at pair i: {a[2i+3], a[2i+2], a[2i+1], a[2i], a[2i-1]}."""
    result = 0
    for shift, k in enumerate([2*i-1, 2*i, 2*i+1, 2*i+2, 2*i+3]):
        result |= _get_bit(value, k, width) << shift
    return result


def _check_exact(window):
    return window == 0b00100 or window == 0b11011


def _check_approx(window):
    return window in (0b00100, 0b00101, 0b00110, 0b11011, 0b11010, 0b11001)


def recode_w(value, mode, width):
    """
    Returns list of n_pairs = width//2 tuples (neg, one, two).
8
    mode: 'standard', 'exact', 'approx_1'..'approx_4'
    """
    n_pairs = width // 2

    digits = []
    for i in range(n_pairs):
        a_high = _get_bit(value, 2*i+1, width)
        a_mid  = _get_bit(value, 2*i,   width)
        a_low  = _get_bit(value, 2*i-1, width)
        digits.append(list(_booth_digit(a_high, a_mid, a_low)))

    if mode == 'standard':
        return digits

    if mode == 'exact':
        approx_until = 0
    elif mode.startswith('approx_'):
        approx_until = 2 * int(mode.split('_')[1])
    else:
        raise ValueError(f"unknown mode: {mode!r}")

    skip_next = False
    i = 0
    while i < n_pairs - 1:
        if skip_next:
            skip_next = False
            i += 1
            continue

        window = _get_window(value, i, width)
        approx_allowed = (i < approx_until)

        if _check_exact(window):
            neg_i = digits[i][0]
            digits[i]   = [neg_i ^ 1, 0, 1]
            digits[i+1] = [0, 0, 0]
            skip_next = True
        elif approx_allowed and _check_approx(window):
            if window in (0b00100, 0b00101, 0b00110):
                digits[i] = [0, 0, 1]
            else:
                digits[i] = [1, 0, 1]
            digits[i+1] = [0, 0, 0]
            skip_next = True

        i += 1

    return digits


def recode_w_with_stats(value, mode, width):
    """
    Like recode_w(), but also returns pattern-hit statistics.

    Returns: (digits, stats)
        stats = {'natural_zeros': int, 'exact_recodes': int, 'approx_recodes': int}
    """
    n_pairs = width // 2

    digits = []
    for i in range(n_pairs):
        a_high = _get_bit(value, 2*i+1, width)
        a_mid  = _get_bit(value, 2*i,   width)
        a_low  = _get_bit(value, 2*i-1, width)
        digits.append(list(_booth_digit(a_high, a_mid, a_low)))

    if mode == 'exact':
        approx_until = 0
    elif mode.startswith('approx_'):
        approx_until = 2 * int(mode.split('_')[1])
    elif mode == 'standard':
        approx_until = 0
    else:
        raise ValueError(f"unknown mode: {mode!r}")

    n_exact = 0
    n_approx = 0

    if mode != 'standard':
        skip_next = False
        i = 0
        while i < n_pairs - 1:
            if skip_next:
                skip_next = False
                i += 1
                continue

            window = _get_window(value, i, width)
            approx_allowed = (i < approx_until)

            if _check_exact(window):
                neg_i = digits[i][0]
                digits[i]   = [neg_i ^ 1, 0, 1]
                digits[i+1] = [0, 0, 0]
                skip_next = True
                n_exact += 1
            elif approx_allowed and _check_approx(window):
                if window in (0b00100, 0b00101, 0b00110):
                    digits[i] = [0, 0, 1]
                else:
                    digits[i] = [1, 0, 1]
                digits[i+1] = [0, 0, 0]
                skip_next = True
                n_approx += 1

            i += 1

    # Natural zeros — счёт по исходным (до перекодирования) тройкам.
    n_natural = 0
    for i in range(n_pairs):
        a_high = _get_bit(value, 2*i+1, width)
        a_mid  = _get_bit(value, 2*i,   width)
        a_low  = _get_bit(value, 2*i-1, width)
        if (a_high, a_mid, a_low) in ((0, 0, 0), (1, 1, 1)):
            n_natural += 1

    stats = {
        'natural_zeros':  n_natural,
        'exact_recodes':  n_exact,
        'approx_recodes': n_approx,
    }
    return digits, stats


def digits_to_vec(digits, width):
    """Pack n_pairs tuples into 3*n_pairs-bit integer: {two[n-1:0], one[n-1:0], neg[n-1:0]}."""
    n_pairs = width // 2
    neg_bits = 0
    one_bits = 0
    two_bits = 0
    for i, (n, o, t) in enumerate(digits):
        neg_bits |= (n & 1) << i
        one_bits |= (o & 1) << i
        two_bits |= (t & 1) << i
    return (two_bits << (2 * n_pairs)) | (one_bits << n_pairs) | neg_bits


def algebraic_value_w(digits):
    """Reconstruct the coefficient value from Booth digits."""
    total = 0
    for i, (n, o, t) in enumerate(digits):
        mag = 2 if t else (1 if o else 0)
        if n:
            mag = -mag
        total += mag * (1 << (2 * i))
    return total


def _self_test():
    import random
    random.seed(42)
    for width in [8, 16, 20]:
        lo = -(1 << (width - 1))
        hi = (1 << (width - 1)) - 1
        for mode in ('standard', 'exact'):
            for _ in range(500):
                a = random.randint(lo, hi)
                digits = recode_w(a, mode, width)
                got = algebraic_value_w(digits)
                # wrap to width bits
                mod = 1 << width
                got = got % mod
                if got >= (1 << (width - 1)):
                    got -= mod
                assert got == a, f"width={width} mode={mode} a={a}: got {got}"
    print("booth_recoder_generic self-test passed.")


if __name__ == "__main__":
    _self_test()
