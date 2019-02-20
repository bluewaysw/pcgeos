/* getppid.c 4.1 82/12/04 */

#include "SYS.h"

PSEUDO(getppid,getpid) /* ppid = getppid() */
       movl    d1,d0
       rts
