/* brk.c 4.2 83/07/26 */

#include "SYS.h"

#define        SYS_brk         17

       .globl  curbrk
       .globl  minbrk

ENTRY(brk)             /* brk(addr) */
    	link	a6, #0
#ifdef is68k
       movl    a6@(8),d1
       cmpl    minbrk,d1
       jge     ok
       movl    minbrk,d1
ok:
       movl    #SYS_brk,d0
       trap    #1
       jcs     1f
       movl    d1,curbrk
#else
       movl 	a6@(8), d0
       addql	#3, d0
       moveq	#-4,d1
       andl 	d1,d0
       movl    	d0,sp@-
       movl 	a6@(4),sp@-
       movl    	#SYS_brk,sp@-
       trap #0
       jcs  	1f
       movl 	sp@(4),curbrk
#endif
       movq    #0,d0
       unlk a6
       rts
1:
       jmp     Cerror
