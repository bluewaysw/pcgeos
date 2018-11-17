##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Startup/WinDemo
# FILE: 	local.mk
# AUTHOR: 	Don Reeves
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don	11/14/00	Initial version 
#
# DESCRIPTION:
#	Special definitions for Welcome
#
#	$Id:$
#
###############################################################################

# Must make sure that PRODUCT_WIN_DEMO is defined - that's the whole point!
# 
ASMFLAGS	+= -DWELCOME -DGPC -DPRODUCT_WIN_DEMO
UICFLAGS	+= -DWELCOME -DGPC -DPRODUCT_WIN_DEMO

#include    <$(SYSMAKEFILE)>
