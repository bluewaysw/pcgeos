/* sbrk.c 4.2 83/07/26 */

#include "SYS.h"

#define        SYS_brk         17

       .globl  _end
       .globl  minbrk
       .globl  curbrk

       .data
minbrk: .long  _end
curbrk:        .long   _end
       .text

ENTRY(sbrk)            /* sbrk(incr) */
	link	a6, #0    
	movl	curbrk,d0
	movl	a6@(8),d1
	beqs	1f		/* If increment is 0, we're done */
	addl	d0,d1
	movl	d0,sp@-		/* Save current break point for return */
	movl	d1,curbrk	/* Assume it will work */
#ifdef is68k
	movl	#SYS_brk,d0
	trap	#1
#else
	movl	d1, sp@-
	movl	a6@(4), sp@-
	movl	#SYS_brk,sp@-
	trap	#0
	lea 	sp@(8), sp  	/* Pop junk */
#endif
	bcss	2f
	movl	sp@+,d0 	/* Return previous break point */
1:
	unlk	a6
	rts
2:
	movl	sp@+,curbrk	/* Restore old break point */
	jmp	Cerror		/* Go handle the error */
