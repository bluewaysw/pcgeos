##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Welcome
# FILE: 	local.mk
# AUTHOR: 	Brian Chin
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	brianc	10/22/92	Initial version 
#
# DESCRIPTION:
#	Special definitions for Welcome
#
#	$Id: local.mk,v 1.1 97/04/04 16:52:47 newdeal Exp $
#
###############################################################################

ASMFLAGS	+= -DWELCOME -DGPC

UICFLAGS	+= -DWELCOME -DGPC

#include    <$(SYSMAKEFILE)>
