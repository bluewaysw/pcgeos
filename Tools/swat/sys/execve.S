/* execve.c 4.1 82/12/04 */

#include "SYS.h"

SYSCALL(execve)                /* execve(name, argv, envp) */
       rts
