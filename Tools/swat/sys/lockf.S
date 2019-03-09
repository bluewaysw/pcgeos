/* lockf.c 1.0 85/11/21 */

#include "SYS.h"

SYSCALL(lockf)         /* ISI: res = lockf(fd, function, size) */
       rts
