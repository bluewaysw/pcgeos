##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Keyboard drivers -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 19, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/19/89		Initial Revision
#
# DESCRIPTION:
#	Wrong name for directory, and we don't *do* error checking...
#
#	$Id: local.mk,v 1.1 97/04/18 11:47:07 newdeal Exp $
#
###############################################################################
GEODE		= kbd
NO_EC		= 1

# for protocol number support -- ardeb
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf

LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall

#include <$(SYSMAKEFILE)>

#
# If the target is "Zoomer" then specify the conditional
# compilation directives on the command line for the assembler.
#
# ASMFLAGS	+= $(.TARGET:X\\[Zoomer\\]/*:S|Zoomer| -DHARDWARE_TYPE=ZOOMER |g)

# full		:: Zoomer

#
# If the target is "NIKE" then specify the conditional
# compilation directives on the command line for the assembler.
#
# ASMFLAGS	+= $(.TARGET:X\\[NIKE\\]/*:S|NIKE| -DHARDWARE_TYPE=NIKE |g)

# full		:: NIKE	
