/* mount.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(mount)         /* 4.3: mount(special, name, rwflag) */
       clrl    d0      /* NFS: mount(type, dir, flags, data) */
       rts
