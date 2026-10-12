#!/usr/bin/env python3
"""Record all results, then fail on routed timing/DRV/DRC violations."""
import collections,json,pathlib,sys,xml.etree.ElementTree as ET
root=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else pathlib.Path('/workspace/build/physical')
variant=sys.argv[1]
metrics=json.loads((root/f'logs/nangate45/rv32i_core/{variant}/6_report.json').read_text())
errors=[]
for key in ['finish__timing__setup__ws','finish__timing__hold__ws']:
 if metrics[key]<0:errors.append(f'{key}: {metrics[key]}')
for suffix in ['max_slew','max_cap','max_fanout','setup_violation_count','hold_violation_count']:
 key='finish__timing__drv__'+suffix
 if metrics[key]!=0:errors.append(f'{key}: {metrics[key]}')
drc=root/f'reports/nangate45/rv32i_core/{variant}/6_drc.lyrdb'
items=ET.parse(drc).findall('.//items/item')
categories=dict(collections.Counter(x.findtext('category') for x in items))
if items:errors.append(f'{len(items)} KLayout DRC markers: {categories}')
lvs=root/f'lvs-{variant}.txt'
result=dict(variant=variant,setup_slack_ns=metrics['finish__timing__setup__ws'],hold_slack_ns=metrics['finish__timing__hold__ws'],standard_cell_area_um2=metrics['finish__design__instance__area__stdcell'],vectorless_power_w=metrics['finish__power__total'],klayout_drc_markers=len(items),drc_categories=categories,lvs=lvs.read_text().strip() if lvs.exists() else 'No LVS result recorded',errors=errors)
(root/f'summary-{variant}.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
if errors:sys.exit(1)
