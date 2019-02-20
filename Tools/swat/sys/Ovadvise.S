/* Ovadvise.c 4.1 82/12/04 */

#include "SYS.h"

#define        SYS_vadvise     72
#define        SETARG_vadvise  SETARG_1
#define        RESTOR_vadvise  RESTOR_1

SYSCALL(vadvise)       /* vadvise(???) */
       rts
