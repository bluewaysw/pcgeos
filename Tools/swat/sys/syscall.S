/* syscall.c 4.2 83/06/27 */

#include "SYS.h"

#ifdef is68k
ENTRY(syscall)         /* syscall( number, arg, ...) */
       movl    sp@(4),d0
       movml   a2-a6,sp@-
       movml   sp@(28),d1/a0-a6
       trap    #1
       movml   sp@+,a2-a6
       jcs     1f
       rts
1:
       jmp     cerror
#else
   foo:	    /* give it something in its symbol table */
#endif
