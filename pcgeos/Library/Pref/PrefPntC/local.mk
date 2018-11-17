# $Id: local.mk,v 1.1 97/04/05 01:32:39 newdeal Exp $

PROTOCONST	= PREF_MODULE

#if $(PRODUCT) == "NDO2000"
#else
#ASMFLAGS	+= -DGPC_ONLY
#UICFLAGS	+= -DGPC_ONLY
#LINKFLAGS	+= -DGPC_ONLY
#endif

#include	<$(SYSMAKEFILE)>
