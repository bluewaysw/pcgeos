/* wait.c 4.1 82/12/28 */

#include "SYS.h"

SYSCALL(wait)          /* pid = wait(status) */
       tstl    sp@(4)
       jeq     1f
       movl    sp@(4),a0
       movl    d1,a0@
1:
       rts
