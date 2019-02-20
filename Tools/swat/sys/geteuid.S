/* geteuid.c 4.1 82/12/04 */

#include "SYS.h"

PSEUDO(geteuid,getuid) /* uid = getuid() */
       movl    d1,d0   /* euid = geteuid() */
       rts
