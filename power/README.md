# CPU output isolation and power-intent experiment

I added an optional wrapper with output isolation and a reset-on-restart contract. The normal CPU and its implementation flow are unchanged. `cpu.upf` describes a top domain, a CPU domain and output isolation in the parent domain.

## Sequence

1. Stop useful execution, assert `isolate` and `reset` while power is present.
2. Remove power only with isolation and reset asserted.
3. Restore power while holding isolation and reset.
4. Apply at least two reset clock edges before releasing reset and isolation.

There is no retention: register contents and PC restart at zero. The wrapper does not generate a gated clock or a physical power switch. External logic controls power sequencing. All outputs, including memory requests and retirement signals, clamp to zero while isolated.

```sh
bash power/check.sh
python3 power/negative.py
# Requires Docker; parses power intent with the pinned OpenROAD image.
docker run --rm --platform linux/amd64 --entrypoint bash \
  -v "$PWD:/workspace" "$(cat physical/image.txt)" /workspace/power/in-container.sh
```

The Icarus test runs three shutdown/restart cycles. It explicitly forces every switched-domain output to X during modeled power loss, checks isolation, and checks execution restarts with cleared state. Mutations remove retirement isolation and violate sequencing; both must fail. Core reset clocks continue during this digital test. This is a behavioral supply-loss model, not native UPF-driven simulation: Icarus does not interpret the UPF. The OpenROAD check separately reads and writes power intent; it does not validate the simulation model against the UPF or insert/sign off isolation cells.

Power-switch mapping, supply nets, retention, level shifters, physical multi-domain implementation and power-aware gate-level verification are outside this experiment. No power savings are measured here. The Nangate45 mapping is used to provide a linked netlist for the UPF parser, not to claim a power-gated implementation.
