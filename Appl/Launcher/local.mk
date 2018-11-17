##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Launcher
# FILE: 	local.mk
#
#	$Id: local.mk,v 1.1 97/04/04 16:13:53 newdeal Exp $
#
###############################################################################
#
#	Define flags to handle the GCM version, program is called "launcher"
#
GEODE		= launcher
GCM		= 1

ASMFLAGS += -Wall
LINKFLAGS += -Wunref

#.MAIN	: launchergcm.geo
#include <$(SYSMAKEFILE)>
