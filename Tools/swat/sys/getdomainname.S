/* @(#)getdomainname.c 1.1 86/02/03 SMI */

#include "SYS.h"

SYSCALL(getdomainname) /* len = getdomainname(buf, buflen) */
       rts
