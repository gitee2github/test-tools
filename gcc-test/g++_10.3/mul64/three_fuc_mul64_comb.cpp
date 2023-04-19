/* { dg-do run } */
/* { dg-options "-O2 -Wno-psabi -fmerge-mull -fdump-tree-forwprop1-details -save-temps" } */

#include <cstdio>

#include <iostream>
#include <cstdlib>
#  define BN_BITS4        32
#  define BN_MASK2        (0xffffffffffffffffL)
#  define BN_MASK2l       (0xffffffffL)
#  define BN_MASK2h       (0xffffffff00000000L)
#  define BN_MASK2h1      (0xffffffff80000000L)
#  define LBITS(a)        ((a)&BN_MASK2l)
#  define HBITS(a)        (((a)>>BN_BITS4)&BN_MASK2l)
#  define L2HBITS(a)      (((a)<<BN_BITS4)&BN_MASK2)




int mul64(unsigned long in0, unsigned long in1, unsigned long &l, unsigned long &h) {
    unsigned long m, m1, lt, ht, bl, bh;
    lt = LBITS(in0);
    ht = HBITS(in0);
    bl = LBITS(in1);
    bh = HBITS(in1);
    m  = bh * lt;
    lt = bl * lt;
    m1 = bl * ht;
    ht = bh * ht;
    m  = (m + m1) & BN_MASK2;
    if (m < m1) ht += L2HBITS((unsigned long)1);
    ht += HBITS(m);
    m1 = L2HBITS(m);
    lt = (lt + m1) & BN_MASK2; if (lt < m1) ht++;
    lt += 1;
    l  = lt;
    h  = ht;
    int result = l + h;
    return result;
}

int mul64_2(unsigned long in0, unsigned long in1, unsigned long &l, unsigned long &h) {
    unsigned long m, m1, lt, ht, bl, bh;
    lt = LBITS(in0);
    ht = HBITS(in0);
    bl = LBITS(in1);
    bh = HBITS(in1);
    m  = bh * lt;
    lt = bl * lt;
    m1 = bl * ht;
    ht = bh * ht;
    m  = (m + m1) & BN_MASK2;
    if (m < m1) ht += L2HBITS((unsigned long)1);
    ht += HBITS(m);
    m1 = L2HBITS(m);
    lt = (lt + m1) & BN_MASK2; if (lt < m1) ht++;
    lt += 1;
    l  = lt;
    h  = ht;
    int result = l + h;
    return result;
}

int mul64_3(unsigned long in0, unsigned long in1, unsigned long &l, unsigned long &h) {
    unsigned long m, m1, lt, ht, bl, bh;
    lt = LBITS(in0);
    ht = HBITS(in0);
    bl = LBITS(in1);
    bh = HBITS(in1);
    m  = bh * lt;
    lt = bl * lt;
    m1 = bl * ht;
    ht = bh * ht;
    m  = (m + m1) & BN_MASK2;
    if (m < m1) ht += L2HBITS((unsigned long)1);
    ht += HBITS(m);
    m1 = L2HBITS(m);
    lt = (lt + m1) & BN_MASK2; if (lt < m1) ht++;
    lt += 1;
    l  = lt;
    h  = ht;
    int result = l + h;
    return result;
}

int main(){
unsigned long a = 10;
unsigned long b = 2;
unsigned long c = 30;
unsigned long d = 40;
unsigned long e = 10;
unsigned long f = 2;
unsigned long g = 30;
unsigned long h = 40;
unsigned long i = 4;
unsigned long j = 8;
unsigned long k = 16;
unsigned long l = 24;
int res = mul64(a, b, c, d) + mul64_2(e, f, g, h) + mul64_3(i, j, k, l);
printf("%d",res);
if (res != 75){
    abort();
}
return 0;
}

/* { dg-final { scan-tree-dump "gimple_simplified to" "forwprop1" } } */
/* { dg-final { scan-assembler "umulh"} } */
