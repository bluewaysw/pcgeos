##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	Pen -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	Chris Lee, June 29th, 94.
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	CL	6/29/94		Initial revision
#
# DESCRIPTION:
#	Pen special makefile definitions
#
#	$Id: local.mk,v 1.1 97/04/05 01:28:07 newdeal Exp $
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
