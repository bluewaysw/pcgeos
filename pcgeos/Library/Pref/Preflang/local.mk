# $Id: local.mk,v 1.1 97/04/05 01:43:43 newdeal Exp $

PROTOCONST	= PREF_MODULE

#
# Compilation constants
#
#if $(PRODUCT) == "NDO2000"
#else
# jfh - see what the non-GPC version looks like
#ASMFLAGS	+= -DGPC_VERSION
#UICFLAGS	+= -DGPC_VERSION
#LINKFLAGS	+= -DGPC_VERSION
#endif

#include <$(SYSMAKEFILE)>
