# PC/GEOS uses webpfilter.asm for WebPFilterSimple/24/26 (_pascal symbols
# WEBPFILTERSIMPLE/24/26). The C reference is only used by WEBP_HOST_TEST.
# Both webpvp8 and webpfilter use WebPDspCode. Glue records the first object's
# filename for the merged segment and uses it to find C static functions.
# Keep ESP last so those functions resolve against webpvp8, not webpfilter.
OBJS := $(OBJS:Nwebpfilter.obj) webpfilter.obj
EOBJS := $(EOBJS:Nwebpfilter.eobj) webpfilter.eobj
GOBJS := $(GOBJS:Nwebpfilter.gobj) webpfilter.gobj

#include <$(SYSMAKEFILE)>

XCCOMFLAGS += -zu
