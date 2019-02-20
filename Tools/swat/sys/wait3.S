/*     @(#)wait3.c     4.2     (Berkeley)      12/28/82        */

/*
 * C library -- wait3
 *
 * pid = wait3(&status, flags, &rusage);
 *
 * pid == -1 if error
 * status indicates fate of process, if given
 * flags may indicate process is not to hang or
 * that untraced stopped children are to be reported.
 * rusage optionally returns detailed resource usage information
 */
#include "SYS.h"

#define        SYS_wait3       SYS_wait

ENTRY(wait3)
       link 	a6,#0
       SETARG_3
       movw    #0x001F,cc      /* this is real dumb */
#ifdef is68k
       movl    #SYS_wait3,d0
       trap    #1
#else
       movl    #SYS_wait3,sp@-
       trap 	#0
#endif
       RESTOR_3
       jcc     1f
       jmp  	Cerror
1:
       tstl    a6@(8)          /* status desired? */
       jeq     2f              /* no */
       movl    a6@(8),a0
       movl    d1,a0@          /* store child's status */
2:
	unlk	a6
       rts
