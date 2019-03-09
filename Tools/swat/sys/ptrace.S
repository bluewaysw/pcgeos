/* ptrace.c 4.2 83/06/30 */

#include "SYS.h"

ENTRY(ptrace)          /* ptrace(request, pid, addr, data) */
       .globl  _errno
       movq    #0,d0
       movl    d0,_errno
       SETARG_ptrace
#ifdef is68k
       movl    #SYS_ptrace,d0
       trap    #1
#else
       movl 	#SYS_ptrace,sp@-
       trap 	#0
#endif
       RESTOR_ptrace
       jcs     1f
       rts
1:
       jmp     cerror
