##############################################################################
#
#       Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:      PC GEOS
# MODULE:       GeoDex
# FILE:         local.mk
# AUTHOR:       Ted Kim
#
#       $Id: local.mk,v 1.1 97/04/04 15:51:04 newdeal Exp $
#
###############################################################################
#
#       Pass flags to handle the GCM version
#
GEODE           = geodex

#ASMFLAGS += -Wall
LINKFLAGS += -Wunref

# Define SEND_CONTROL during linking if it's not a NIKE or PIZZA version
LINKFLAGS += $(.TARGET:H:NNIKE:NPIZZA:S/^/-DSEND_CONTROL/:X\\[-DSEND_CONTROL\\]*)
# Define IMPEX_MERGE during linking if it's not a NIKE or PIZZA version
LINKFLAGS += $(.TARGET:H:NNIKE:NPIZZA:S/^/-DIMPEX_MERGE/:X\\[-DIMPEX_MERGE\\]*)

.PATH.ui        : UI $(INSTALL_DIR)/UI Art $(INSTALL_DIR)/Art
UICFLAGS        += -IUI -I$(INSTALL_DIR)/UI

#include <$(SYSMAKEFILE)>

#
# GPC usability tweaks
#
# add export feature -- brianc 8/23
#
#ASMFLAGS        += -DGPC -DEXPORT
#UICFLAGS        += -DGPC -DEXPORT
#LINKFLAGS       += -DGPC -DEXPORT

#if $(PRODUCT) == "NDO2000"
#else
#ASMFLAGS	+= -DGPC_ONLY
#UICFLAGS	+= -DGPC_ONLY
#LINKFLAGS	+= -DGPC_ONLY
#endif

#Breadbox settings
ASMFLAGS += -DEXPORT
UICFLAGS += -DEXPORT
LINKFLAGS += -DEXPORT
