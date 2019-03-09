/* SYS.h 4.1 83/11/22 */

#include <syscall.h>
#include "NARG.h"

#ifdef is68k
#ifdef PROF
#define        ENTRY(x)        .globl _##x; .align 1; _##x: .data; .align 1; 1: .long 0; .text; lea 1b,a1; jsr mcount
#else
#define        ENTRY(x)        .globl _##x; .align 1; _##x:
#endif PROF
#define        SYSCALL(x)      ENTRY(x); link a6, \#0; SETARG_##x; movl \#SYS_##x,d0; trap \#1; RESTOR_##x; jcc 1f; jmp Cerror; 1: unlk a6
#define        PSEUDO(x,y)     ENTRY(x); link a6, \#0; SETARG_##y; movl \#SYS_##y,d0; trap \#1; RESTOR_##y; unlk a6

#define        SETARG_0
#define        RESTOR_0

#define        SETARG_1        movl a6@(8),d1
#define        RESTOR_1

#define        SETARG_2        movml a6@(8),d1/a0
#define        RESTOR_2

#define        SETARG_3        movml a6@(8),d1/a0-a1
#define        RESTOR_3

#define        SETARG_4        movl a2,sp@-; movml a6@(8),d1/a0-a2
#define        RESTOR_4        movl sp@+,a2

#define        SETARG_5        movml a2-a3,sp@-; movml a6@(8),d1/a0-a3
#define        RESTOR_5        movml sp@+,a2-a3

#define        SETARG_6        movml a2-a4,sp@-; movml a6@(8),d1/a0-a4
#define        RESTOR_6        movml sp@+,a2-a4

#define        SETARG_7        movml a2-a5,sp@-; movml a6@(8),d1/a0-a5
#define        RESTOR_7        movml sp@+,a2-a5

#define        SETARG_8        movml a2-a6,sp@-; movml a6@(8),d1/a0-a6
#define        RESTOR_8        movml sp@+,a2-a6

#else /* sun */

#ifdef PROF
#define        ENTRY(x)        .globl _##x; .align 1; _##x: .data; .align 1; 1: .long 0; .text; lea 1b,a1; jsr mcount
#else
#define        ENTRY(x)        .globl _##x; .align 1; _##x:
#endif PROF
#define        SYSCALL(x)      ENTRY(x); link a6, \#0; SETARG_##x; pea SYS_##x; trap \#0; RESTOR_##x; jcc 1f; jmp Cerror; 1: unlk a6
#define        PSEUDO(x,y)     ENTRY(x); link a6, \#0; SETARG_##y; pea SYS_##y; trap \#0; RESTOR_##y; unlk a6

/*
 * Re-create the stack frame as if the link weren't there...
 */
#define        SETARG_0	       movl a6@(4),sp@-
#define        RESTOR_0

#define        SETARG_1        movl a6@(8),sp@-; SETARG_0
#define        RESTOR_1

#define        SETARG_2        movl a6@(12),sp@-; SETARG_1
#define        RESTOR_2

#define        SETARG_3        movl a6@(16),sp@-; SETARG_2
#define        RESTOR_3

#define        SETARG_4        movl a6@(20),sp@-; SETARG_3
#define        RESTOR_4        

#define        SETARG_5        movl a6@(24),sp@-; SETARG_4
#define        RESTOR_5        

#define        SETARG_6        movl a6@(28),sp@-; SETARG_5
#define        RESTOR_6        

#define        SETARG_7        movl a6@(32),sp@-; SETARG_6
#define        RESTOR_7        

#define        SETARG_8        movl a6@(36),sp@-; SETARG_7
#define        RESTOR_8        
#endif
       .globl  Cerror
