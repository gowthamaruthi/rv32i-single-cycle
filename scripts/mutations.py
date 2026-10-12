#!/usr/bin/env python3
"""Isolated functional mutations: compilation errors do not count as detection."""
import pathlib, subprocess, sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
source=(ROOT/'rtl/rv32i_core.sv').read_text()
mutations={
 'arithmetic_shift':('result=$signed(a) >>> b[4:0]','result=a >> b[4:0]'),
 'subtract':('a-b : a+b','a+b : a+b'),
 'byte_lane':("4'b0001 << address[1:0]","4'b0001"),
}
for name,(old,new) in mutations.items():
    assert old in source
    directory=ROOT/'build'/'mutations'/name;directory.mkdir(parents=True,exist_ok=True)
    rtl=directory/'rv32i_core.sv';rtl.write_text(source.replace(old,new))
    run=subprocess.run([sys.executable,str(ROOT/'scripts/regress.py'),'--rtl',str(rtl),'--build',str(directory),'--directed-only'],capture_output=True,text=True,timeout=60)
    log=run.stdout+run.stderr;(directory/'detection.log').write_text(log)
    assert run.returncode!=0 and 'AssertionError: directed retirement' in log,(name,log)
    print('PASS detected functional mutation:',name)
