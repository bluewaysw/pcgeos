##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	APM Power Manager local make file
# FILE: 	local.mk
# AUTHOR: 	Todd Stumpf, Jul 28, 1994
#
#	$Id$
#
###############################################################################
#
GEODE		= apm11

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

.PATH.asm .PATH.def : ../Common $(INSTALL_DIR:H)/Common  ../APMCommon $(INSTALL_DIR:H)/APMCommon

PROTOCONST	= POWER

#include <$(SYSMAKEFILE)>
