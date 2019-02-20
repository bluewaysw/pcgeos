/* execl.c 4.1 82/12/04 */

#include "SYS.h"

ENTRY(execl)           /* execl(name, arg0, arg1, ... , 0) */
       pea     sp@(8)
       movl    sp@(8),sp@-
       jsr     _execv
       addql   #8,sp
       rts
