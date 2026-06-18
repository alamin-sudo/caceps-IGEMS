# IGEMS: Integrated Global Emissions Management System

**Computational framework for equitable global carbon budget allocation**

## Paper

"Treating Nature as Capital Is Not Enough: A Computational Framework for Equitable Global Carbon Budget Allocation"

**Authors:** Abul Quasem Al-Amin & Naomi Oreskes

**Submitted to:** Nature Sustainability (2026)

## Instructions for GAMS ## 
Treating Nature as Capital Is Not Enough: A Computational Framework for Equitable Global Carbon Budget Allocation

Here is a complete GAMS 25 implementation of IGEMS. 

It is a single runnable .gms file. The core model (Sections 1 to 7) needs no solver, since IGEMS is a deterministic simulation. Only the optional weight optimiser in Section 8 calls a MIP solver.

What it contains:

The nine-region baseline data exactly as in our workbook, with derived totals, GDP per capita, and the per-capita benchmark.
All four allocation rules. Market, equity, capacity, and hybrid are coded straight from Section 3.4. The piecewise development bonus and capacity multiplier use layered $ conditions so each region lands in exactly one band.
The 50-year geometric-decay trajectory.

The metrics: compliance rate, justice index, development surplus, per-capita ratio, and the conditioned 1.5°C success-probability heuristic.
Budget sensitivity over 300, 400, 500, and 900 Gt, and decarbonization-rate sensitivity over 1.5 to 3.5 percent.

An optional MIP that picks hybrid weights to maximise compliant region-years, since the paper itself notes 40:35:25 is a choice, not an optimum. The solve line is commented so the file runs.

The allocations reproduce Table 2 exactly. The justice indices match sheet 7 exactly (market 37.7, equity 83.8, capacity 18.6, hybrid 47.6), the per-capita ratios match, and the rate-sensitivity endpoints match sheet 8 (for example 10.21 Gt at 2.5 percent).

Note on Compliance definition: compliant if E(i,t) ≤ A(i), averaged over regions and years, computed faithfully, it yields market 0.00, equity 0.35, capacity 0.61, hybrid 0.42. The workbook [additional econometric analysis is used] reports market 0.22, equity 0.67, capacity 0.44, hybrid 0.78. The two disagree in ranking. The market allocation is about 28 percent of current emissions, so a region's slowly decaying emissions stay above that small target for almost the whole horizon, which forces market compliance toward zero under the literal formula.

Because the 1.5°C success probabilities are derived from the compliance rate,Thus the headline 22, 67, 44, 78 and the probabilities 20, 50, 50, 85 come from stylised compliance definition rather than GAMS outcomes. The sheet 5 workbook compliance trajectory supports this, since it shows non-integer region shares and a flat 22 percent for the market. 

## Quick Start

```bash
pip install -r requirements.txt
python run_replication.py


