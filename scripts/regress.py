#!/usr/bin/env python3
import argparse,json,pathlib,subprocess,sys
ROOT=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'verification'))
from model import Model,Trap
from programs import suite,I,R,B,J

def words(path):
    return [int(x,16) for line in path.read_text().splitlines() if not line.startswith('//') for x in line.split()]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--rtl',type=pathlib.Path,default=ROOT/'rtl/rv32i_core.sv');parser.add_argument('--build',type=pathlib.Path,default=ROOT/'build');parser.add_argument('--directed-only',action='store_true');args=parser.parse_args()
    build=args.build.resolve();build.mkdir(parents=True,exist_ok=True)
    assert I(0x13,1,0,0,5)==0x00500093 and R(3,0,1,2)==0x002081b3
    assert B(0,0,0,8)==0x00000463 and J(1,8)==0x008000ef
    executable=build/'core.vvp'
    subprocess.run(['iverilog','-g2012','-s','tb_core','-o',str(executable),str(args.rtl),str(ROOT/'tb/tb_core.sv')],check=True)
    summary=[];coverage=set()
    for name,program in suite():
        if args.directed_only and name!='directed':continue
        case=build/name;case.mkdir(exist_ok=True)
        model=Model();expected=[]
        for n in range(10000):
            assert model.pc%4==0 and model.pc//4<len(program),(name,model.pc)
            try:expected.append(model.step(program[model.pc//4]))
            except Trap as trap:expected_trap=[model.pc,trap.cause];break
        else:raise RuntimeError('reference did not terminate')
        (case/'program.hex').write_text(''.join(f'{v:08x}\n' for v in program+[0x13]*(4096-len(program))))
        command=['vvp',str(executable),f'+PROGRAM={case}/program.hex',f'+TRACE={case}/trace.txt',f'+MEMORY={case}/memory.hex',f'+REGISTERS={case}/registers.hex']
        run=subprocess.run(command,cwd=case,capture_output=True,text=True,timeout=30)
        (case/'simulation.log').write_text(run.stdout+run.stderr)
        try:
            assert run.returncode==0,run.stdout+run.stderr
            rows=(case/'trace.txt').read_text().splitlines()
            actual=[[int(x,16) for x in line.split()[1:]] for line in rows if line.startswith('RET')]
            actual_trap=[[int(x,16) for x in line.split()[1:]] for line in rows if line.startswith('TRAP')]
            for i,(got,want) in enumerate(zip(actual,expected)):
                assert got==want,f'{name} retirement {i}: got={got}, expected={want}'
            assert len(actual)==len(expected),(name,'retirement count')
            assert actual_trap==[expected_trap],(name,'trap',actual_trap,expected_trap)
            assert words(case/'memory.hex')==list(model.mem),(name,'memory mismatch')
            assert words(case/'registers.hex')==model.reg,(name,'register mismatch')
        except (AssertionError,FileNotFoundError):
            subprocess.run(command+['+WAVES'],cwd=case,capture_output=True,text=True,timeout=30)
            raise
        coverage |= model.coverage
        summary.append(dict(name=name,retired=len(expected),trap_pc=expected_trap[0],trap_cause=expected_trap[1]))
        print(f'PASS {name}: {len(expected)} retirements, trap={expected_trap[1]}')
    required=set('LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU LB LH LW LBU LHU SB SH SW ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI ADD SUB SLL SLT SLTU XOR SRL SRA OR AND FENCE'.split())
    required |= {name+suffix for name in ['BEQ','BNE','BLT','BGE','BLTU','BGEU'] for suffix in ['_taken','_not_taken']}
    assert required<=coverage,sorted(required-coverage)
    result=dict(cases=summary,total_retired=sum(x['retired'] for x in summary),observed_operations_and_branch_outcomes=sorted(coverage))
    (build/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'PASS {len(summary)} programs, {result["total_retired"]} retirements compared; all required operation/outcome bins observed')
if __name__=='__main__':main()
