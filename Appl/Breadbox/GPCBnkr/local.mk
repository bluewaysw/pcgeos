#include <$(SYSMAKEFILE)>

# Enable compilation of GPC specific code.

XGOCFLAGS  += -DCOMPILEGPC
XLINKFLAGS += -DCOMPILEGPC

#if $(PRODUCT) == "NDO2000"
# Enable all features for NewDeal Office.
#else
XGOCFLAGS	+= -DGPC_ONLY
XLINKFLAGS	+= -DGPC_ONLY
#endif
