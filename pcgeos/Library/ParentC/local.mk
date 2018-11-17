#include    "$(SYSMAKEFILE)"

#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_ONLY
UICFLAGS	+= -DGPC_ONLY
LINKFLAGS	+= -DGPC_ONLY
#endif
