"""Small independent architectural reference, not an official compliance model."""
MASK=(1<<32)-1

def signed(x,bits=32):
    x &= (1<<bits)-1
    return x-(1<<bits) if x>>(bits-1) else x

class Trap(Exception):
    def __init__(self,cause):self.cause=cause

class Model:
    def __init__(self):
        self.reg=[0]*32;self.pc=0;self.mem=bytearray((i*37+11)&255 for i in range(4096))
        self.coverage=set()
    def step(self,word):
        op=word&127;rd=(word>>7)&31;f=(word>>12)&7;r1=(word>>15)&31;r2=(word>>20)&31;top=word>>25
        x,y=self.reg[r1],self.reg[r2];imm=signed(word>>20,12)
        new_pc=(self.pc+4)&MASK;value=None;request=[0,0,0,0];name=''
        if op==0x37:value=word&0xfffff000;name='LUI'
        elif op==0x17:value=self.pc+(word&0xfffff000);name='AUIPC'
        elif op==0x6f:
            offset=signed(((word>>31)<<20)|(((word>>12)&255)<<12)|(((word>>20)&1)<<11)|(((word>>21)&1023)<<1),21)
            new_pc=(self.pc+offset)&MASK;value=self.pc+4;name='JAL'
            if new_pc%4:raise Trap(0)
        elif op==0x67:
            if f!=0:raise Trap(2)
            new_pc=((x+imm)&MASK)&~1;value=self.pc+4;name='JALR'
            if new_pc%4:raise Trap(0)
        elif op==0x63:
            predicates={0:x==y,1:x!=y,4:signed(x)<signed(y),5:signed(x)>=signed(y),6:x<y,7:x>=y}
            names={0:'BEQ',1:'BNE',4:'BLT',5:'BGE',6:'BLTU',7:'BGEU'}
            if f not in predicates:raise Trap(2)
            taken=predicates[f];name=names[f];self.coverage.add(name+('_taken' if taken else '_not_taken'))
            if taken:
                offset=signed(((word>>31)<<12)|(((word>>7)&1)<<11)|(((word>>25)&63)<<5)|(((word>>8)&15)<<1),13)
                new_pc=(self.pc+offset)&MASK
                if new_pc%4:raise Trap(0)
        elif op in (0x03,0x23):
            store=op==0x23
            if store:
                if f not in (0,1,2):raise Trap(2)
                offset=signed(((word>>25)<<5)|rd,12);size=1<<f
                name=['SB','SH','SW'][f]
            else:
                if f not in (0,1,2,4,5):raise Trap(2)
                offset=imm;size=1<<(f&3);name={0:'LB',1:'LH',2:'LW',4:'LBU',5:'LHU'}[f]
            address=(x+offset)&MASK
            if address%size:raise Trap(6 if store else 4)
            if address+size>len(self.mem):raise ValueError('program outside memory contract')
            request=[1,address,0,0]
            if store:
                request[2]=((1<<size)-1)<<(address%4);request[3]=(y<<(8*(address%4)))&MASK
                for i in range(size):self.mem[address+i]=(y>>(8*i))&255
            else:
                raw=int.from_bytes(self.mem[address:address+size],'little')
                value=signed(raw,size*8) if f<4 else raw
        elif op in (0x13,0x33):
            immediate=op==0x13;rhs=imm&MASK if immediate else y
            if not immediate and not(top==0 or top==32 and f in(0,5)):raise Trap(2)
            if immediate and f in(1,5) and not(top==0 or top==32 and f==5):raise Trap(2)
            amount=rhs&31
            if f==0:
                sub=not immediate and top==32
                value=x-rhs if sub else x+rhs;name='SUB' if sub else ('ADDI' if immediate else 'ADD')
            elif f==1:value=x<<amount;name='SLLI' if immediate else 'SLL'
            elif f==2:value=int(signed(x)<signed(rhs));name='SLTI' if immediate else 'SLT'
            elif f==3:value=int(x<rhs);name='SLTIU' if immediate else 'SLTU'
            elif f==4:value=x^rhs;name='XORI' if immediate else 'XOR'
            elif f==5:
                arithmetic=top==32;value=(signed(x) if arithmetic else x)>>amount
                name=('SRA' if arithmetic else 'SRL')+('I' if immediate else '')
            elif f==6:value=x|rhs;name='ORI' if immediate else 'OR'
            else:value=x&rhs;name='ANDI' if immediate else 'AND'
        elif op==0x0f and f==0:name='FENCE'
        elif word==0x73:raise Trap(11)
        elif word==0x100073:raise Trap(3)
        else:raise Trap(2)
        self.coverage.add(name)
        destination=rd if value is not None else 0
        data=(value&MASK) if destination else 0
        if destination:self.reg[destination]=data
        trace=[self.pc,word,destination,data]+request
        self.pc=new_pc
        return trace
