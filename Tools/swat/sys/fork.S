/* fork.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(fork)          /* pid = fork() */
       tstw    d1
       jeq     1f
       movq    #0,d0
1:
       rts
