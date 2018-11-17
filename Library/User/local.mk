##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Generic UI -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 15, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for the generic ui
#
#	$Id: local.mk,v 1.1 97/04/07 11:45:41 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

# This makes pmake xref output more useful.
PCXREF		+= -suiec.sym

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI Help $(INSTALL_DIR)/Help

UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI -IHelp -I$(INSTALL_DIR)/Help -IUser -I$(INSTALL_DIR)/User

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE		= ui

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify each of the Bullet conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# Jedi XIP version
#
ASMFLAGS        += $(.TARGET:X\\[JediXIP\\]/*:S|JediXIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP
