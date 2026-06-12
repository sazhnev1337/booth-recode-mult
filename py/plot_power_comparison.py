#!/usr/bin/env python3
"""
Сравнение мощности разных конфигураций умножителя.

Главный график — все DUT в реалистичном сценарии (gauss_slow).
Доп. график — то же для всех 4 сценариев.
"""

import re
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np

from pathlib import Path
FIGURES_DIR = Path(__file__).resolve().parent / "figures"
FIGURES_DIR.mkdir(exist_ok=True)

REPORTS_DIR = Path("../pwr/reports")


def read_power(rpt_path):
    """Извлекает Total power из OpenSTA-отчёта."""
    if not rpt_path.exists():
        return None
    text = rpt_path.read_text()
    m = re.search(r"^Total\s+\S+\s+\S+\s+\S+\s+(\S+)", text, re.MULTILINE)
    if m:
        return float(m.group(1))
    return None


def get_all_data():
    """Читает все мощности из reports/, возвращает dict[config][scenario] -> µW."""
    scenarios = ['uniform_fast', 'uniform_slow', 'gauss_fast', 'gauss_slow']
    extrec_modes = ['standard', 'exact', 'approx_1', 'approx_2']
    data = {}

    for scn in scenarios:
        v = read_power(REPORTS_DIR / f"power_booth_{scn}.rpt")
        data.setdefault('booth', {})[scn] = v * 1e6 if v is not None else None

        for mode in extrec_modes:
            cfg = f"booth_extrec_{mode}"
            v = read_power(REPORTS_DIR / f"power_booth_extrec_{scn}_{mode}.rpt")
            data.setdefault(cfg, {})[scn] = v * 1e6 if v is not None else None

    return data


def plot_main_comparison(data):
    """Главный график: все DUT в gauss_slow."""
    configs = ['booth',
               'booth_extrec_standard', 'booth_extrec_exact',
               'booth_extrec_approx_1', 'booth_extrec_approx_2']
    short_names = ['booth\n(internal\nencoder)',
                   'booth_extrec\nstandard', 'booth_extrec\nexact',
                   'booth_extrec\napprox_1', 'booth_extrec\napprox_2']

    values = [data[cfg]['gauss_slow'] for cfg in configs]

    colors = ['#888888', '#3b82f6',
              '#10b981', '#10b981', '#ef4444', '#ef4444']
    # Чуть варьируем оттенки для extrec.
    alphas = [1.0, 1.0, 0.6, 1.0, 0.6, 1.0]

    fig, ax = plt.subplots(figsize=(10, 10))
    bars = ax.bar(np.arange(len(configs)), values, color=colors, alpha=None,
                  edgecolor='black', linewidth=0.5)
    for bar, alpha in zip(bars, alphas):
        bar.set_alpha(alpha)

    # Подписи значений над столбиками.
    for i, v in enumerate(values):
        ax.text(i, v + 5, f'{v:.0f}', ha='center', va='bottom', fontsize=13)

    ax.set_xticks(np.arange(len(configs)))
    ax.set_xticklabels(short_names, fontsize=13)
    ax.set_ylabel('Power, µW', fontsize=14)
    ax.set_title('Power consumption (gauss_slow scenario, realistic for adaptive filter)', fontsize=14)
    ax.tick_params(axis='y', labelsize=13)
    ax.set_ylim(0, max(values) * 1.15)
    ax.grid(axis='y', alpha=0.3)

    # Линия baseline для визуальной отсечки.
    ax.axhline(y=data['booth']['gauss_slow'], color='#3b82f6',
               linestyle='--', alpha=0.5, linewidth=1)
    ax.text(len(configs) - 0.5, data['booth']['gauss_slow'] + 3,
            'booth baseline', color='#3b82f6', fontsize=12, ha='right')

    plt.tight_layout()
    out = FIGURES_DIR / "power_dut_comparison_gauss_slow.png"
    plt.savefig(out, dpi=120, bbox_inches='tight')
    print(f"Saved: {out}")


def plot_scaling_by_recoding(data):
    """Зависимость мощности booth_extrec от уровня recoding для 4 сценариев."""
    modes = ['standard', 'exact', 'approx_1', 'approx_2']
    x = np.arange(len(modes))

    scenarios = ['uniform_fast', 'uniform_slow', 'gauss_fast', 'gauss_slow']
    colors = {
        'uniform_fast': "#09609f",
        'uniform_slow': "#5d92d7",
        'gauss_fast':   "#d71717",
        'gauss_slow':   "#f04744",
    }

    fig, ax = plt.subplots(figsize=(9, 6))

    for scn in scenarios:
        values = [data[f'booth_extrec_{mode}'][scn] for mode in modes]
        ax.plot(x, values, marker='o', label=scn, color=colors[scn], linewidth=2)

    ax.set_xticks(x)
    ax.set_xticklabels(modes)
    ax.set_xlabel('Recoding mode')
    ax.set_ylabel('Power, µW')
    ax.set_title('booth_extrec power vs recoding level (4 scenarios)')
    ax.grid(True, alpha=0.3)
    ax.legend()

    plt.tight_layout()
    out = FIGURES_DIR / "power_extrec_vs_recoding_mode.png"
    plt.savefig(out, dpi=120, bbox_inches='tight')
    print(f"Saved: {out}")


def main():
    data = get_all_data()

    # Проверим, что все цифры загрузились.
    for cfg, scns in data.items():
        for scn, v in scns.items():
            if v is None:
                print(f"WARNING: missing data for {cfg} / {scn}")

    plot_main_comparison(data)
    plot_scaling_by_recoding(data)
    plt.show()


if __name__ == "__main__":
    main()
