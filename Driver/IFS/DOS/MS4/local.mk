# $Id: local.mk,v 1.1 97/04/10 11:54:56 newdeal Exp $

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common

PROTOCONST	= FS

#include <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

#
# GPC additions
#
#ASMFLAGS	+= -DSEND_DOCUMENT_FCN_ONLY=TRUE -DGPC
#LINKFLAGS	+= -DSEND_DOCUMENT_FCN_ONLY=TRUE -DGPC
