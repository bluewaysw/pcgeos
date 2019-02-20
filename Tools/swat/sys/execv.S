/* execv.c 4.2 82/12/29 */

#include "SYS.h"

ENTRY(execv)           /* execv(name, argv) */
       movl    _environ,sp@-
       movl    sp@(12),sp@-
       movl    sp@(12),sp@-
       jsr     _execve
       lea     sp@(3*4),sp
       rts
