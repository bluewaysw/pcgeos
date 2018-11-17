# $Id: local.mk,v 1.1 97/04/05 01:32:09 newdeal Exp $

PROTOCONST	= PREF_MODULE

#
# Different App icon
#
#ifdef $(PRODUCT) == "NDO2000"
#else
#ASMFLAGS	+= -DGPC_ONLY
#UICFLAGS	+= -DGPC_ONLY
#LINKFLAGS	+= -DGPC_ONLY
#endif
#ASMFLAGS	+= -DGPC_VERSION
#UICFLAGS	+= -DGPC_VERSION
#LINKFLAGS	+= -DGPC_VERSION

#include	<$(SYSMAKEFILE)>
