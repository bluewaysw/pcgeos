#
#	Local makefile for: chart
#
#	$Id: local.mk,v 1.1 97/04/04 17:46:12 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#
# XIP
#
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# PIZZA flags
#
ASMFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)
UICFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)
LINKFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DSPIDER_CHART |g)

#include <$(SYSMAKEFILE)>

#
# GPC usability tweaks
#
ASMFLAGS	+= -DGPC -DGPC_ART
UICFLAGS	+= -DGPC -DGPC_ART
LINKFLAGS	+= -DGPC_ART
