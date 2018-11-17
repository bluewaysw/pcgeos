##############################################################################
#
#       Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:      GEOS
# MODULE:       ConView Library
# FILE:         local.mk
# AUTHOR:       
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#
# DESCRIPTION:
#
#       $Id: local.mk,v 1.1 97/04/04 17:49:55 newdeal Exp $
#
###############################################################################

.PATH.uih .PATH.ui: Main NavControl CtxtControl FindControl SendControl Art \
						$(INSTALL_DIR)/Main \
						$(INSTALL_DIR)/NavControl \
						$(INSTALL_DIR)/CtxtControl \
						$(INSTALL_DIR)/FindControl \
						$(INSTALL_DIR)/SendControl \
						$(INSTALL_DIR)/Art 
UICFLAGS        += -IMain -INavControl -ICtxtControl -IFindControl \
                 -ISendControl -IArt\
		-I$(INSTALL_DIR)/Main \
		-I$(INSTALL_DIR)/NavControl \
		-I$(INSTALL_DIR)/CtxtControl \
		-I$(INSTALL_DIR)/FindControl \
		-I$(INSTALL_DIR)/SendControl \
		-I$(INSTALL_DIR)/Art

#ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK

#
# XIP in Jedi version
#
ASMFLAGS        += $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#include <$(SYSMAKEFILE)>

PCXREFFLAGS     += -sconview.sym


