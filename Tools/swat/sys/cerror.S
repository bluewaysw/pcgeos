/* cerror.c 4.1 82/12/04 */

#include "SYS.h"

       .globl  _errno
Cerror:
       movl    d0,_errno
       movq    #-1,d0
       unlk    a6
       rts
