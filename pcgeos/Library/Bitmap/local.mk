##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Bitmap
# FILE: 	local.mk
# AUTHOR: 	
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ian	9/9/98 		needed to add local.mk
#
# DESCRIPTION:
#	Special definitions for the generic ui
#
#
#
###############################################################################

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#include <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP


