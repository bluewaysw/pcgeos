# Database local.mk

#if $(PRODUCT) == "NDO2000"
#else
GOCFLAGS += -DGPC_ONLY
LINKFLAGS += -DGPC_ONLY
#endif

#include <$(SYSMAKEFILE)>
