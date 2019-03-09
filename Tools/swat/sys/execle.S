/* execle.c 4.1 82/12/04 */

#include "SYS.h"

ENTRY(execle)          /* execl(name, arg0, arg1, , 0, envp) */
       lea     sp@(8),a0
       movl    a0,a1
       movq    #-1,d1
1:     tstl    a0@+
       dbeq    d1,1b
       jne     1b
       movl    a0@,sp@-
       movl    a1,sp@-
       movl    sp@(12),sp@-
       jsr     _execve
       lea     sp@(3*4),sp
       rts
