##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Spooler -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Tony Requist
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	2/9/90		Initial Revision
#
# DESCRIPTION:
#	Special definitions for the spooler
#
#	$Id: local.mk,v 1.1 97/04/07 11:11:39 newdeal Exp $
#
###############################################################################

#
# Define whether or not label support is present
#
#if $(PRODUCT) == "NDO2000"
#else
#ASMFLAGS   	+= -DGPC_ONLY -DGPC_ART -DLABELS
#UICFLAGS   	+= -DGPC_ONLY -DGPC_ART -DLABELS
#endif

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI Art $(INSTALL_DIR)/UI $(INSTALL_DIR)/Art
UICFLAGS        += -IUI -IArt -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Art

#
# GPC additions
#
#ASMFLAGS	+= -DGPC
#UICFLAGS	+= -DGPC

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

