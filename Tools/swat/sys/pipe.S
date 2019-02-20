/* pipe.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(pipe)          /* pipe(fildes) */
       movl    sp@(4),a0
       movl    d0,a0@+
       movl    d1,a0@
       movq    #0,d0
       rts
