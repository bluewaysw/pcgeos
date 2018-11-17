##############################################################################
#
#	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Swap Library
# FILE:		local.mk
#
# REVISION HISTORY:
#	clee	6/94		Initial version
#
# DESCRIPTION:	
#
# RCS STAMP:
#	$Id: local.mk,v 1.1 97/04/07 11:15:45 newdeal Exp $
#
##############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS        += -IUI -I$(INSTALL_DIR)/UI

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify each of the Bullet conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP
