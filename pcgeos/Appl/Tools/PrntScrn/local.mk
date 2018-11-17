##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Appl/Tools/PrntScrn
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Aug 15, 1994
#
#	$Id: local.mk,v 1.1 97/04/04 17:15:32 newdeal Exp $
#
###############################################################################
#
# No error-checking version of this app
#
NO_EC		= 1

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#include <$(SYSMAKEFILE)>
