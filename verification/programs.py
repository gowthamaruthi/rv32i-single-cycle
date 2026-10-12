"""Instruction encoders and finite, deterministic verification programs."""
import random

def I(op,rd,f,rs,imm):return ((imm&4095)<<20)|(rs<<15)|(f<<12)|(rd<<7)|op

def R(rd,f,a,b,top=0):return (top<<25)|(b<<20)|(a<<15)|(f<<12)|(rd<<7)|0x33

def S(f,a,b,imm):
    v=imm&4095
    return ((v>>5)<<25)|(b<<20)|(a<<15)|(f<<12)|((v&31)<<7)|0x23

def B(f,a,b,imm):
    v=imm&8191
    return ((v>>12)<<31)|(((v>>5)&63)<<25)|(b<<20)|(a<<15)|(f<<12)|(((v>>1)&15)<<8)|(((v>>11)&1)<<7)|0x63

def J(rd,imm):
    v=imm&0x1fffff
    return ((v>>20)<<31)|(((v>>1)&1023)<<21)|(((v>>11)&1)<<20)|(((v>>12)&255)<<12)|(rd<<7)|0x6f

def directed():
    p=[I(0x13,31,0,0,512),I(0x13,1,0,0,-1),0x80000137,I(0x13,3,0,0,1),I(0x13,0,0,0,77)]
    for f in range(8):p += [R(4,f,1,3),R(5,f,2,3)]
    p += [R(4,0,2,3,32),R(4,5,2,3,32)]
    for f in (0,2,3,4,6,7):p += [I(0x13,6,f,2,-1),I(0x13,6,f,1,-2048)]
    for n in (0,1,31):p += [I(0x13,7,1,3,n),I(0x13,7,5,2,n),I(0x13,7,5,2,1024+n)]
    p += [0x12345437,0x00001497]
    for f in (0,1,4,5,6,7):
        for a,b in ((1,3),(3,1),(1,1)):
            p += [B(f,a,b,8),I(0x13,8,0,8,1)]
    p += [I(0x13,10,0,0,5),I(0x13,10,0,10,-1),B(1,10,0,-4)]
    p += [J(11,8),I(0x13,0,0,0,0)]
    target=(len(p)+3)*4
    p += [I(0x13,12,0,0,target|1),I(0x67,12,0,12,0),I(0x13,0,0,0,0)]
    for f in (0,1,2):
        size=1<<f
        for off in range(0,8,size):p += [S(f,31,2,off),I(3,13,f,31,off)]
    for f in (0,1,2,4,5):p += [I(3,14,f,31,-4)]
    p += [I(0x13,15,0,0,37),R(16,1,3,15),R(16,5,2,15,32),0x0ff0000f,0x00100073]
    return p

def random_program(seed,n=1200):
    r=random.Random(seed);p=[I(0x13,31,0,0,512)]
    for k in range(n):
        rd=r.randrange(31);a=r.randrange(32);b=r.randrange(32);kind=r.randrange(7)
        if kind==0:
            f=r.randrange(8);p.append(R(rd,f,a,b,32 if f in(0,5) and r.randrange(2) else 0))
        elif kind==1:
            f=r.randrange(8);imm=r.randrange(-2048,2048)
            if f in (1,5):imm=r.randrange(32)+(1024 if f==5 and r.randrange(2) else 0)
            p.append(I(0x13,rd,f,a,imm))
        elif kind==2:p.append((r.getrandbits(20)<<12)|(rd<<7)|r.choice([0x17,0x37]))
        elif kind==3:
            f=r.choice([0,1,2,4,5]);off=r.randrange(-128,128);off-=off%(1<<(f&3));p.append(I(3,rd,f,31,off))
        elif kind==4:
            f=r.randrange(3);off=r.randrange(-128,128);off-=off%(1<<f);p.append(S(f,31,b,off))
        elif kind==5:p.extend([B(r.choice([0,1,4,5,6,7]),a,b,8),I(0x13,0,0,0,0)])
        else:p.extend([J(rd,8),I(0x13,0,0,0,0)])
    p.append(0x100073);return p

def suite():
    yield 'directed',directed()
    for seed in range(10):yield f'random_{seed}',random_program(seed)
    tests={'ecall':[0x73], 'illegal':[0xffffffff], 'csr':[0x00101073], 'fence_i':[0x100f],
        'bad_shift':[I(0x13,1,1,0,32)],'bad_reg':[R(1,0,0,0,1)],
        'bad_jalr':[I(0x67,1,1,0,0)],'bad_branch':[B(2,0,0,0)],
        'bad_load':[I(3,1,3,0,0)],'bad_store':[S(3,0,1,0)],
        'jal_align':[J(1,2)],'jalr_align':[I(0x67,1,0,0,3)],'branch_align':[B(0,0,0,2)],
        'untaken_unaligned':[B(1,0,0,2),0x100073]}
    for f in (1,2,5):tests[f'load_align_{f}']=[I(3,1,f,0,1)]
    for f in (1,2):tests[f'store_align_{f}']=[S(f,0,1,1)]
    for name,p in tests.items():yield name,p
