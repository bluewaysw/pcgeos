##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Spline
# FILE: 	local.mk
# AUTHOR: 	Skarphedinn Hedinsson
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	skarpi	05/94		Initial Revision
#
# DESCRIPTION:
#	Special definitions for the graphic
#
#	$Id: local.mk,v 1.1 97/04/07 11:10:03 newdeal Exp $
#
###############################################################################

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

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

