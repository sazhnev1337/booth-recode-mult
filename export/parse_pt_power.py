#!/usr/bin/env python3
"""
parse_pt_power.py  —  summary table from PrimeTime power reports.

Run from: pwr/
    python3 ../export/parse_pt_power.py

Expects reports in pwr/rpt/ with names:
    power_naive_<scenario>.rpt
    power_booth_<scenario>.rpt
    power_booth_extrec_<scenario>_<mode>.rpt

Parses the PrimeTime line:
    Total Power        = 2.341e-04 (100.00%)

Output: printed table + pwr/rpt/summary_pt.txt
"""

import re
import sys
from pathlib import Path

RPT_DIR   = Path("rpt")
OUT_FILE  = RPT_DIR / "summary_pt.txt"

SCENARIOS    = ["uniform_fast", "uniform_slow", "gauss_fast", "gauss_slow"]
EXTREC_MODES = ["standard", "exact", "approx_1", "approx_2"]

# Row label → report filename template (use {scn} and optionally {mode})
CONFIGS = [
    ("naive",                   "power_naive_{scn}.rpt"),
    ("booth",                   "power_booth_{scn}.rpt"),
    ("extrec_standard",         "power_booth_extrec_{scn}_standard.rpt"),
    ("extrec_exact",            "power_booth_extrec_{scn}_exact.rpt"),
    ("extrec_approx_1",         "power_booth_extrec_{scn}_approx_1.rpt"),
    ("extrec_approx_2",         "power_booth_extrec_{scn}_approx_2.rpt"),
]

_TOTAL_RE = re.compile(r"Total\s+Power\s*=\s*([\d.e+\-]+)", re.IGNORECASE)


def parse_total_power(path: Path) -> str:
    """Return total power string from a PT report, or '-' if not found."""
    if not path.exists():
        return "-"
    try:
        text = path.read_text(errors="replace")
    except OSError:
        return "-"
    m = _TOTAL_RE.search(text)
    if not m:
        return "-"
    try:
        val = float(m.group(1))
        # convert to µW for readability
        return f"{val * 1e6:.2f}"
    except ValueError:
        return m.group(1)


def build_table() -> list[str]:
    col_w  = 14
    lbl_w  = 22

    header = f"{'config':<{lbl_w}}" + "".join(f"{s:>{col_w}}" for s in SCENARIOS)
    sep    = "-" * len(header)

    lines = [
        "Power summary (Total Power, µW)",
        "Source: pwr/rpt/power_*.rpt  |  tool: PrimeTime",
        sep,
        header,
        sep,
    ]

    for label, tmpl in CONFIGS:
        row = f"{label:<{lbl_w}}"
        for scn in SCENARIOS:
            fname = tmpl.format(scn=scn)
            val   = parse_total_power(RPT_DIR / fname)
            row  += f"{val:>{col_w}}"
        lines.append(row)

    lines.append(sep)
    return lines


def main() -> None:
    if not RPT_DIR.exists():
        print(f"ERROR: directory '{RPT_DIR}' not found. Run from pwr/.", file=sys.stderr)
        sys.exit(1)

    lines = build_table()
    text  = "\n".join(lines) + "\n"

    print(text)

    OUT_FILE.write_text(text)
    print(f"Saved → {OUT_FILE}")


if __name__ == "__main__":
    main()
