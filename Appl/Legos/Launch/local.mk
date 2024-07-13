#include <$(SYSMAKEFILE)>

zoomer  :: $(GEODE).geo

CCOMFLAGS += -wdef -wuse
LINKFLAGS += -r
