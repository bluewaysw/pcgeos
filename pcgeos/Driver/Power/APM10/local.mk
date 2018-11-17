##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	APM Power Manager local make file
# FILE: 	local.mk
# AUTHOR: 	Todd Stumpf, Jul 28, 1994
#
#	$Id: local.mk,v 1.1 97/04/18 11:48:30 newdeal Exp $
#
###############################################################################
#
GEODE		= apmpwr

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common  ../APMCommon $(INSTALL_DIR:H)/APMCommon

PROTOCONST	= POWER

#include <$(SYSMAKEFILE)>
