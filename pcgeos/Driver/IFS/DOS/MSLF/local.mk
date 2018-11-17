# $Id$

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
# Flags for code page supports.
#
ASMFLAGS	+= $(.TARGET:M*SJIS*:S/$(.TARGET)/-2 -DDO_DBCS -DPRODUCT_DBCS -DSJIS_SUPPORT/)
LINKFLAGS	+= $(.TARGET:M*SJIS*:S/$(.TARGET)/-2 -DDO_DBCS -DPRODUCT_DBCS -DSJIS_SUPPORT/)
ASMFLAGS	+= $(.TARGET:M*GB*:S/$(.TARGET)/-2 -DDO_DBCS -DPRODUCT_DBCS -DGB_2312_EUC_SUPPORT/)
LINKFLAGS	+= $(.TARGET:M*GB*:S/$(.TARGET)/-2 -DDO_DBCS -DPRODUCT_DBCS -DGB_2312_EUC_SUPPORT/)

#
# GPC additions
#
#ASMFLAGS	+= -DSEND_DOCUMENT_FCN_ONLY=TRUE -DGPC
#LINKFLAGS	+= -DSEND_DOCUMENT_FCN_ONLY=TRUE -DGPC
