#!/usr/bin/env bash
set -euo pipefail
variant=$1
source /OpenROAD-flow-scripts/env.sh
cd /OpenROAD-flow-scripts/flow
mkdir -p /workspace/build/physical
{ openroad -version; yosys -V; klayout -v; } > "/workspace/build/physical/versions-$variant.txt"
make DESIGN_CONFIG=/workspace/physical/config.mk WORK_HOME=/workspace/build/physical FLOW_VARIANT="$variant" 2>&1 | tee "/workspace/build/physical/run-$variant.log"
make DESIGN_CONFIG=/workspace/physical/config.mk WORK_HOME=/workspace/build/physical FLOW_VARIANT="$variant" drc > "/workspace/build/physical/checks-$variant.log" 2>&1
if [[ -f platforms/nangate45/lvs/FreePDK45.lylvs ]]; then
  make DESIGN_CONFIG=/workspace/physical/config.mk WORK_HOME=/workspace/build/physical FLOW_VARIANT="$variant" lvs >> "/workspace/build/physical/checks-$variant.log" 2>&1
  echo 'executed; inspect LVS database for equivalence' > "/workspace/build/physical/lvs-$variant.txt"
else
  echo 'UNSUPPORTED: bundled Nangate45 LVS deck is absent; LVS not run' | tee "/workspace/build/physical/lvs-$variant.txt"
fi
python3 /workspace/physical/check-results.py "$variant"
