##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Parse -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	John Wedgwood, January 31st, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	John	 1/31/91	Initial Revision
#
# DESCRIPTION:
#	Parse special makefile definitions
#
#	$Id: local.mk,v 1.1 97/04/04 17:44:45 newdeal Exp $
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
