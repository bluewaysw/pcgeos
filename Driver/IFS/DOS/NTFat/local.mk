# $Id: local.mk,v 1.1 98/01/24 23:24:17 gene Exp $

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common ../OS2 $(INSTALL_DIR:H)/OS2

PROTOCONST	= FS

#include <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

