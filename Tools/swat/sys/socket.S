/* socket.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(socket)                /* s = socket(af, type, protocol) */
       rts
