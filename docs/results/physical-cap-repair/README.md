# Capacitance repair and antenna findings

[Run 38273760896](https://github.com/gowthamaruthi/rv32i-single-cycle/actions/runs/38273760896), source `0e916e7`, uses a 15% capacitance-repair margin. Both routed designs have zero reported setup, hold, slew, capacitance and fanout violations. The run still fails: its LVS target refers to a missing platform deck, and review of the completed KLayout DRC reports finds antenna markers.

| Strategy | Cell area (um²) | Setup slack (ns) | Hold slack (ns) | Vectorless power estimate (mW) | KLayout antenna markers |
|---|---:|---:|---:|---:|---:|
| Baseline | 17857.9 | 3.88230 | 0.00650199 | 2.32503 | 5 |
| Area-oriented ABC | 18148.9 | 3.56137 | 0.00336725 | 2.43980 | 3 |

The baseline markers include long nets from the `clk` and `imem_rdata[17]` ports. The follow-up experiment bounds input/data wire lengths and the clock-root wire to 30 um before routing, then reruns the same KLayout rules. These reports are preserved as failed physical-check evidence; there is no DRC waiver or LVS pass.

The script counts DRC **items**, rather than the upstream helper's count of `<value>` fields: a single marker may contain several values. Raw `drc.lyrdb` reports retain the geometry and category of each marker.
