/* writev.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(writev)                /* cc = writev(fd, iov, ioveclen) */
       rts
