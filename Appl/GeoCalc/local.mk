#
#	Local makefile for: geoCalc
#
#	$Id: local.mk,v 1.1 97/04/04 15:49:06 newdeal Exp $
#

#
# Define the Bullet-specific version
#
#ASMFLAGS	+= -DBULLET
#UICFLAGS	+= -DBULLET

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref


#
# XIP
#
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# XIP in Jedi version
#
ASMFLAGS	+= $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)


.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include <$(SYSMAKEFILE)>

# #if $(PRODUCT) == "NDO2000"
# # Enable all features for NewDeal Office.
# #else
# ASMFLAGS	+= -DGPC_ONLY -DDOS_LONG_NAME_SUPPORT
# UICFLAGS	+= -DGPC_ONLY -DDOS_LONG_NAME_SUPPORT
# LINKFLAGS	+= -DGPC_ONLY
# #endif
#
# GPC usability tweaks
#
# ASMFLAGS	+= -DGPC -DSUPER_IMPEX
# UICFLAGS	+= -DGPC -DSUPER_IMPEX
# LINKFLAGS	+= -DGPC
