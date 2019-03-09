/* exect.c 4.2 82/12/17 */

#include "SYS.h"
#include <machine/psl.h>

ENTRY(exect)           /* exect(name, argv, envp) */
       /* KLUDGE: can't set trace bit in user mode */
       jmp     _execve
