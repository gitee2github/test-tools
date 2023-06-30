/*自指向结构体，优化触发*/
/* { dg-do compile } */
/* { dg-do run } */

#include <stdlib.h>

typedef struct str_t1 str_t;
struct str_t1 {
    int a;
    struct str_t1 *b;
};

#ifdef STACK_SIZE
#if STACK_SIZE > 16000
#define N 1000
#else
#define N (STACK_SIZE / 16)
#endif
#else
#define N 1000
#endif

int num;

int main ()
{
    int i, r;

    r = rand ();
    num = r > N ? N : r; 
    str_t *p1 = calloc(num, sizeof(str_t));
    str_t *p2 = calloc(num, sizeof(str_t));
    if (p1 == NULL) {
	return 0;
    }
    for (i = 0; i < num; i++) {
	p1[i].a = 1;
    }
    for (i = 0; i < num; i++) {
	p1[i].b = &(p1[i+1]);
    }
    for (i = 0; i < num; i++) {
	if (p1[i].a != 1) {
	    abort ();
	}
    }
    if (p2 == NULL) {
	return 0;
    }
    for (i = 0; i < num; i++) {
	p2[i].a = 1;
    }
    for (i = 0; i < num; i++) {
	p2[i].b = &(p2[i+1]);
    }
    for (i = 0; i < num; i++) {
	if (p2[i].a != 1) {
	    abort ();
	}
    }
    free(p1);
    free(p2);

    return 0;
}

/*--------------------------------------------------------------------------*/
/* { dg-final { scan-ipa-dump "Number of structures to transform in semi-relayout is 1" "struct_reorg" } } */