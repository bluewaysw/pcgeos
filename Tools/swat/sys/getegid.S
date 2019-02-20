/* getegid.c 4.1 82/12/04 */

#include "SYS.h"

PSEUDO(getegid,getgid) /* gid = getgid() */
       movl    d1,d0   /* gid = getegid() */
       rts
