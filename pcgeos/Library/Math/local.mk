# $Id: local.mk,v 1.1 97/04/05 01:23:33 newdeal Exp $
# Turn on warnings which are normally off.
#
LINKFLAGS       += -Wunref
ASMFLAGS        += -Wall

#
# XIP
# 
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# Include the system makefile
#
#include        <$(SYSMAKEFILE)>

#
# GPC usability tweaks
#
ASMFLAGS	+= -DGPC
UICFLAGS	+= -DGPC

#if $(PRODUCT) == "NDO2000"
#else
ASMFLAGS	+= -DGPC_ONLY
UICFLAGS	+= -DGPC_ONLY
LINKFLAGS	+= -DGPC_ONLY
#endif
