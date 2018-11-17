#include <$(SYSMAKEFILE)>

# Enable compilation of GPC specific code.

GOCFLAGS += -DPRODUCT_GPC
LINKFLAGS += -DPRODUCT_GPC
CCOMFLAGS += -DPRODUCT_GPC

#if $(PRODUCT) == "NDO2000"
#else
GOCFLAGS	+= -DGPC_ONLY
LINKFLAGS	+= -DGPC_ONLY
CCOMFLAGS	+= -DGPC_ONLY
#endif
