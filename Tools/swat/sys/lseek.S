/* lseek.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(lseek)         /* lseek(fd, offset, whence) */
       rts
