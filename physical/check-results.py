#!/usr/bin/env python3
"""Fail on routed timing/DRV violations; retain exact upstream metrics."""
import json,pathlib,sys,xml.etree.ElementTree as ET
root=pathlib.Path('/workspace/build/physical');variant=sys.argv[1]
metrics=json.loads((root/f'logs/nangate45/rv32i_core/{variant}/6_report.json').read_text())
for key in ['finish__timing__setup__ws','finish__timing__hold__ws']:
 assert metrics[key]>=0,(key,metrics[key])
for suffix in ['max_slew','max_cap','max_fanout','setup_violation_count','hold_violation_count']:
 key='finish__timing__drv__'+suffix
 assert metrics[key]==0,(key,metrics[key])
drc=root/f'reports/nangate45/rv32i_core/{variant}/6_drc.lyrdb'
items=ET.parse(drc).findall('.//items/item');assert not items,f'{len(items)} KLayout DRC markers'
# KLayout LVS exits nonzero when its deck detects a mismatch; retain its database/log.
result=dict(variant=variant,setup_slack_ns=metrics['finish__timing__setup__ws'],hold_slack_ns=metrics['finish__timing__hold__ws'],standard_cell_area_um2=metrics['finish__design__instance__area__stdcell'],vectorless_power_w=metrics['finish__power__total'],klayout_drc_markers=len(items))
(root/f'summary-{variant}.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
