#!/usr/bin/env python3
import pathlib,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[1]
shell=(ROOT/'power/rv32i_power_shell.sv').read_text()
tb=(ROOT/'power/tb_power.sv').read_text()
for name,rtl,test,expected in [
 ('isolation_leak',shell.replace("assign retire_valid=isolate ? 1'b0 : core_retire_valid;",'assign retire_valid=core_retire_valid;'),tb,'isolation leak'),
 ('unsafe_sequence',shell,tb.replace('power_good=0;','power_good=0;isolate=0;'),'isolation must precede power loss')]:
 out=ROOT/'build/power'/name;out.mkdir(parents=True,exist_ok=True)
 (out/'shell.sv').write_text(rtl);(out/'tb.sv').write_text(test)
 subprocess.run(['iverilog','-g2012','-s','tb_power','-o',str(out/'test.vvp'),str(ROOT/'rtl/rv32i_core.sv'),str(out/'shell.sv'),str(out/'tb.sv')],check=True)
 run=subprocess.run(['vvp',str(out/'test.vvp')],capture_output=True,text=True,timeout=10)
 (out/'failure.log').write_text(run.stdout+run.stderr)
 assert run.returncode and expected in run.stdout,(name,run.stdout,run.stderr)
 print('PASS rejected '+name)
