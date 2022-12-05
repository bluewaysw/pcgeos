##############################################################################
# FILE: 	local.mk
###############################################################################
.PATH.asm .PATH.def	: .. $(INSTALL_DIR:H)

#if $(PRODUCT) == "GEOS2X"
GOCFLAGS += -DPRODUCT_GEOS2X
LINKFLAGS += -DPRODUCT_GEOS2X
#endif

PROTOCONST = MOUSE
LIBNAME = mouse

#include <$(SYSMAKEFILE)>
