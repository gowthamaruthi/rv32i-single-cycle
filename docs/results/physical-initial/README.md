# Initial routed results

[Run 38272459741](https://github.com/gowthamaruthi/rv32i-single-cycle/actions/runs/38272459741), source commit `6d1ef54`, produced routed GDS for both mapping strategies. These are the pre-repair results; capacitance violations remain even though the flow command completed successfully.

| Strategy | Standard-cell area (um²) | Setup slack (ns) | Hold slack (ns) | Vectorless power estimate (mW) | Max-cap violations |
|---|---:|---:|---:|---:|---:|
| Baseline | 17781.6 | 3.82891 | 0.00531286 | 2.30183 | 3 |
| Area-oriented ABC | 18089.1 | 3.56765 | 0.00350561 | 2.42719 | 1 |

The area-oriented mapping did not improve final area in this experiment. Reported power uses tool-default vectorless activity; these are estimates, not measured power or a workload-based power comparison. Both runs use a 10 ns clock and identical I/O budgets at the Nangate45 typical corner. External instruction/data memories are not included.

The original `make` success was insufficient as an acceptance check. I added explicit checks for routed setup/hold and electrical violations, plus physical-rule checking. The new checker rejects these initial reports. The follow-up flow adds a 15% capacitance-repair margin to account for growth between estimated and routed parasitics.

`metrics.json` and `timing.rpt` are preserved tool outputs. OpenROAD's version string in this image is `unknown`; the immutable container digest in the source commit identifies the exact runtime. GDS hashes identify the archived layouts; full build artifacts are attached to the run. No LVS or foundry signoff result is established by this initial run.
