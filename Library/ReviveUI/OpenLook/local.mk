##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	New UI -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 15, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for new ui
#
#	$Id: local.mk,v 1.1 97/04/07 10:56:34 newdeal Exp $
#
###############################################################################
# ASMFLAGS	+= -Wall
# LINKFLAGS	+= -Wunref

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE		= ol

PROTOCONST	= SPUI

#
#	Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS	+= -DOPEN_LOOK

UICFLAGS	+= -DOPEN_LOOK

#include    <$(SYSMAKEFILE)>
