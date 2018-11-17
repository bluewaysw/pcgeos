##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Shell library
# FILE: 	local.mk
# AUTHOR: 	Skarphedinn Hedinsson
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	SSH	5/16/94		Initial version 
#
# DESCRIPTION:
#	Special definitions for GeoManager
#
#	$Id: local.mk,v 1.1 97/04/07 10:45:17 newdeal Exp $
#
###############################################################################

#include    <$(SYSMAKEFILE)>

#
# If the target is "XIP" then specify the conditional
# compilation directives on the command line for the assembler.
#
ASMFLAGS	+= $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#full		:: XIP
