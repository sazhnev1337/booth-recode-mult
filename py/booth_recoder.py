#!/usr/bin/env python3
"""
Booth recoder для адаптивных коэффициентов фильтра.

Принимает 16-битное знаковое число и возвращает 24-битный вектор
{neg[7:0], one[7:0], two[7:0]} — управляющие сигналы PPG для 8 позиций.

Поддерживаемые режимы:
    'standard'   — обычный R4 Booth без перекодирования (baseline reference)
    'exact'      — exact recoding (паттерны 00100, 11011)
    'approx_N'   — approximate recoding, где N (1..4) — число младших пар,
                   в которых разрешены приближённые паттерны.

Алгоритм — последовательный, проверяет все 7 промежуточных позиций
(i=0..6) с приоритетом младшим (как в статье Zhu et al.).
"""

import sys


def get_bit(value, n):
    """Возвращает n-й бит (с учётом знака для отрицательных)."""
    if n < 0:
        return 0
    return (value >> n) & 1


def booth_digit(triplet):
    """
    Обычная R4 Booth-кодировка триплета {a[2i+1], a[2i], a[2i-1]}.
    Возвращает (neg, one, two) — управляющие сигналы PPG.
    """
    a_high = (triplet >> 2) & 1
    a_mid  = (triplet >> 1) & 1
    a_low  = triplet & 1

    neg = a_high
    one = a_mid ^ a_low
    two = (a_high & ~a_mid & ~a_low) | (~a_high & a_mid & a_low)
    # Маскируем до 1 бита (на случай ~ в Python).
    return (neg & 1, one & 1, two & 1)


def get_window(value, i):
    """Возвращает 5-битное окно позиции i: {a[2i+3], a[2i+2], a[2i+1], a[2i], a[2i-1]}."""
    # value — signed16, a[-1] = 0.
    # Для i=7 нужны биты a[17], a[16] — берём как знаковое расширение a[15].
    sign_bit = (value >> 15) & 1
    bits = []
    for k in [2*i+3, 2*i+2, 2*i+1, 2*i, 2*i-1]:
        if k < 0:
            bits.append(0)
        elif k < 16:
            bits.append((value >> k) & 1)
        else:
            bits.append(sign_bit)
    # MSB to LSB: {a[2i+3], a[2i+2], a[2i+1], a[2i], a[2i-1]}
    return (bits[0] << 4) | (bits[1] << 3) | (bits[2] << 2) | (bits[3] << 1) | bits[4]


def check_exact_pattern(window):
    """True если 5-битное окно = 00100 или 11011."""
    return window == 0b00100 or window == 0b11011


def check_approx_pattern(window):
    """True если 5-битное окно = 00100, 00101, 00110, 11011, 11010, 11001."""
    return window in (0b00100, 0b00101, 0b00110, 0b11011, 0b11010, 0b11001)


def recode(value, mode):
    """
    Возвращает список из 8 троек (neg, one, two) — по одной на позицию i=0..7.
    """
    # Обычные Booth-цифры для всех 8 позиций.
    digits = []
    for i in range(8):
        # Триплет позиции i = {a[2i+1], a[2i], a[2i-1]}
        a_high = (value >> (2*i+1)) & 1 if (2*i+1) < 16 else (value >> 15) & 1
        a_mid  = (value >> (2*i))   & 1 if (2*i) < 16 else (value >> 15) & 1
        a_low  = (value >> (2*i-1)) & 1 if (2*i-1) >= 0 and (2*i-1) < 16 else 0
        triplet = (a_high << 2) | (a_mid << 1) | a_low
        digits.append(list(booth_digit(triplet)))  # [neg, one, two]

    if mode == 'standard':
        return digits

    # Определяем, какие позиции допускают approx-паттерны.
    # mode = 'exact'  → ни одна
    # mode = 'approx_N' → младшие 2N позиций (i < 2*N)
    if mode == 'exact':
        approx_until = 0
    elif mode.startswith('approx_'):
        n = int(mode.split('_')[1])
        approx_until = 2 * n
    else:
        raise ValueError(f"unknown mode: {mode}")

    # Последовательный проход с приоритетом младшим.
    # На каждой позиции i смотрим окно и пытаемся применить перекодирование.
    # Если занулили позицию i+1, на следующей итерации i+1 пропускаем.
    skip_next = False
    i = 0
    while i < 7:  # позиции 0..6 могут быть source паттерна; 7 только пассивно
        if skip_next:
            skip_next = False
            i += 1
            continue

        window = get_window(value, i)

        # Решаем, разрешён ли approx на этой позиции.
        approx_allowed = (i < approx_until)

        applied = False

        if check_exact_pattern(window):
            # Точное перекодирование: позиция i выдаёт -M_i (по формуле 8),
            # позиция i+1 зануляется (по формуле 7).
            neg_i, one_i, two_i = digits[i]
            digits[i] = [neg_i ^ 1, 0, 1]   # инверсия знака, |M|=2
            digits[i+1] = [0, 0, 0]
            skip_next = True
            applied = True
        elif approx_allowed and check_approx_pattern(window):
            # Приближённое перекодирование: K_lo = ±2 (по знаку), K_hi = 0.
            # ak1 (window in 00100/00101/00110) → K_lo = +2, neg=0.
            # ak2 (window in 11011/11010/11001) → K_lo = -2, neg=1.
            if window in (0b00100, 0b00101, 0b00110):
                digits[i] = [0, 0, 1]
            else:  # ak2
                digits[i] = [1, 0, 1]
            digits[i+1] = [0, 0, 0]
            skip_next = True
            applied = True

        i += 1

    return digits


def digits_to_24bit(digits):
    """Упаковывает 8 троек в 24-битный вектор: {two[7:0], one[7:0], neg[7:0]}."""
    neg_bits = 0
    one_bits = 0
    two_bits = 0
    for i, (n, o, t) in enumerate(digits):
        neg_bits |= (n & 1) << i
        one_bits |= (o & 1) << i
        two_bits |= (t & 1) << i
    return (two_bits << 16) | (one_bits << 8) | neg_bits


def algebraic_value(digits):
    """Восстанавливает значение из Booth-цифр (для верификации корректности)."""
    total = 0
    for i, (n, o, t) in enumerate(digits):
        magnitude = 0
        if t:
            magnitude = 2
        elif o:
            magnitude = 1
        if n:
            magnitude = -magnitude
        total += magnitude * (1 << (2 * i))
    return total


def self_test():
    import random
    random.seed(0)
    for mode in ['standard', 'exact']:
        for _ in range(1000):
            a = random.randint(-32768, 32767)
            digits = recode(a, mode)
            reconstructed = algebraic_value(digits)
            if reconstructed >= 32768:
                reconstructed -= 65536
            elif reconstructed < -32768:
                reconstructed += 65536
            assert reconstructed == a, f"mode={mode}, a={a}: got {reconstructed}"
    print("Self-test passed: standard and exact are bit-exact.")

if __name__ == "__main__":
    self_test()
