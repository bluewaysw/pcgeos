#
#	Local makefile for: wav
#
#	$Id: local.mk,v 1.1 97/04/07 11:51:30 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_ONLY
LINKFLAGS	+= -DGPC_ONLY
#endif


#include <$(SYSMAKEFILE)>

