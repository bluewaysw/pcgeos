#if $(PRODUCT) == "NDO2000"
#else
UICFLAGS += -DGPC_ONLY
#endif

#include <$(SYSMAKEFILE)>
