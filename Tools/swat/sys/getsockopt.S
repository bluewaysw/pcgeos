/* getsockopt.c 4.1 83/01/13 */

#include "SYS.h"

SYSCALL(getsockopt)    /* getsockopt(s,level,optname,optval,optlen) */
       rts
