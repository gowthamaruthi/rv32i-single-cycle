#!/usr/bin/env bash
set -euo pipefail
variant=$1
source /OpenROAD-flow-scripts/env.sh
cd /OpenROAD-flow-scripts/flow
mkdir -p /workspace/build/physical
{ openroad -version; yosys -V; klayout -v; } > "/workspace/build/physical/versions-$variant.txt"
make DESIGN_CONFIG=/workspace/physical/config.mk WORK_HOME=/workspace/build/physical FLOW_VARIANT="$variant" > "/workspace/build/physical/run-$variant.log" 2>&1
