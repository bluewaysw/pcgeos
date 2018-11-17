##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	SSMeta -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	Chris Lee, Aug 2nd, 94.
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CL	8/2/94		Initial revision
#
# DESCRIPTION:
#	SSMeta special makefile definitions
#
#	$Id: local.mk,v 1.1 97/04/07 10:44:09 newdeal Exp $
#
###############################################################################

#
# Turn on warnings which are normally off.
#
LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall

#
# XIP
# 
ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#
# Include the system makefile
#
#include	<$(SYSMAKEFILE)>
