##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Banner
# FILE: 	local.mk
# AUTHOR: 	Roger Flores, Tue Oct 9 20:41:00 PST 1990
#
#	$Id: local.mk,v 1.1 97/04/04 14:37:32 newdeal Exp $
#
###############################################################################
#
#	Define flags to handle the GCM version, program is called "banner"
#
GEODE		= banner

ASMFLAGS 	+= -Wunreach -Wshadow -DREAD_CHECK -DWRITE_CHECK
LINKFLAGS 	+= -Wunref

#include <$(SYSMAKEFILE)>
