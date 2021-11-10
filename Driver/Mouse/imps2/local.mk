##############################################################################
# FILE: 	local.mk
###############################################################################
.PATH.asm .PATH.def	: .. $(INSTALL_DIR:H)

PROTOCONST = MOUSE
LIBNAME = mouse

#include <$(SYSMAKEFILE)>
