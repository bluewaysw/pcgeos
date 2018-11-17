# $Id: local.mk,v 1.1 97/04/04 16:49:11 newdeal Exp $

PROTOCONST	= PREF_MODULE

LINKFLAGS	+= -N "Flame Fractal"
#ifdef $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_VERSION
UICFLAGS	+= -DGPC_VERSION
LINKFLAGS	+= -DGPC_VERSION
#endif

#include    <$(SYSMAKEFILE)>
