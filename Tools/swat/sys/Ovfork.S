/*
 * @(#)vfork.s 4.1 (Berkeley) 12/21/80
 * C library -- vfork
 */

/*
 * pid = vfork();
 *
 * d1 == 0 in parent process, d1 == 1 in child process.
 * d0 == pid of child in parent, d0 == pid of parent in child.
 */

#include "SYS.h"
#define SYS_vfork 66

ENTRY(vfork)           /* pid = vfork() */
#ifdef is68k
       movl    sp@+,a1         /* a1 must be preserved across sys call */
       movl    #SYS_vfork,d0
       trap    #1
#else
       movl    sp@+,a0
       movl    #SYS_vfork,sp@-
       trap    #0
#endif /* is68k */
       jcs     2f
       tstl    d1              /* parent process */
       jeq     1f              /* yes */
       movq    #0,d0
1:
#ifdef is68k
       jmp     a1@
#else
       jmp  	a0@
#endif

2:
       .globl  _errno
       movl    d0,_errno
       movq    #-1,d0
       jmp     a1@
