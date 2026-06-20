# IGEMS: Integrated Global Emissions Management System

**Computational framework for equitable global carbon budget allocation**

## Paper

"Treating Nature as Capital Is Not Enough: A Computational Framework for Equitable Global Carbon Budget Allocation"

**Authors:** Abul Quasem Al-Amin & Naomi Oreskes

**Submitted to:** Nature Sustainability (2026)

## GAMS outcomes for 'Treating Nature as Capital Is Not Enough: A Computational Framework for Equitable Global Carbon Budget Allocation'

**Here is a complete GAMS syntax implementation of IGEMS**

It is a single runnable .gms file. The core model (Sections 1 to 7) needs no solver, since IGEMS is a deterministic simulation. Only the optional weight optimiser in Section 8 calls a MIP solver.

What it contains:

The nine-region baseline data exactly as in our workbook, with derived totals, GDP per capita, and the per-capita benchmark. All four allocation rules. Market, equity, capacity, and hybrid are coded straight from Section 3.4. The piecewise development bonus and capacity multiplier use layered $ conditions so each region lands in exactly one band. The 50-year geometric-decay trajectory.

The metrics: compliance rate, justice index, development surplus, per-capita ratio, and the conditioned 1.5°C success-probability heuristic. Budget sensitivity over 300, 400, 500, and 900 Gt, and decarbonization-rate sensitivity over 1.5 to 3.5 percent.

An optional MIP that picks hybrid weights to maximise compliant region-years.


## Quick Start

```bash
pip install -r requirements.txt
python run_replication.py
