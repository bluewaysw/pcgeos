##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	New UI -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Lysle E. Shields III, Feb. 4, 2002
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/15/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for new ui
#
#	$Id: local.mk,v 1.1 97/04/07 11:03:17 newdeal Exp $
#
###############################################################################

# search inside COMMENT blocks for tags
PCTAGSFLAGS	+= -c

PROTOCONST	= SPUI

#
#	Pass flag to MASM to define the specific UI that we're making
#
ASMFLAGS	+= -DBBOXUI -wprivate -wunref_local

UICFLAGS	+= -DBBOXUI

#include    <$(SYSMAKEFILE)>


#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP

