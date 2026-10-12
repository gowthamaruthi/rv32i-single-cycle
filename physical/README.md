# Standalone-core implementation experiment

I compare two ABC mapping strategies with the same CPU RTL and constraints: default timing-oriented mapping (`baseline`) and area-oriented mapping (`area`). The flow uses Yosys, OpenROAD's integrated OpenSTA, OpenRCX and KLayout with the public Nangate45 platform. The Linux amd64 container is pinned by digest in `image.txt`.

```sh
bash physical/run.sh baseline
bash physical/run.sh area
```

Docker is required. This Mac does not currently have a container runtime; the initial execution uses GitHub's Ubuntu runner. Logs and generated layout files are uploaded as workflow artifacts. Execution results will be recorded after the runs complete.

The 10 ns clock, 0.1 ns uncertainty, 0.1/2 ns minimum/maximum I/O delays and 0.010 pF output loads are explicit study assumptions. Reset is synchronous and timed. External instruction/data memories are absent; this is not a closed timing model of a complete CPU-plus-memory system. It does not establish the maximum operating frequency of that system. Nangate45 is an educational platform, not a production tapeout target.

Area is mapped standard-cell area. Power reports from vectorless activity are estimates, not measured silicon power. Timing must be evaluated for both setup and hold after routing. A generated GDS file alone is not physical signoff; record DRC/LVS and antenna results separately.

Platform files remain in the pinned upstream container; this repository does not redistribute a proprietary PDK. References: [OpenROAD Flow Scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts), [Nangate45 platform and license](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts/tree/master/flow/platforms/nangate45).
