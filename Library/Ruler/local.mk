##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Ruler -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	John Wedgwood, January 31st, 1991
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	John	 1/31/91	Initial Revision
#
# DESCRIPTION:
#	Ruler special makefile definitions
#
#	$Id: local.mk,v 1.1 97/04/07 10:43:07 newdeal Exp $
#
###############################################################################

#
# Turn on warnings which are normally off.
#
LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall

#
# Include the system makefile
#
#include	<$(SYSMAKEFILE)>
