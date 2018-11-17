##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS Sound System
# MODULE:	Sound Blaster Driver Special make Instructions
# FILE: 	local.mk
# AUTHOR: 	Todd Stumpf, Oct. 06, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	TS	10/06/92	Initial Revision
#
# DESCRIPTION:
#	Sound Blaster special makefile definitions
#
#	$Id: local.mk,v 1.1 97/04/18 11:57:42 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#
#	The target is geos.geo
#
GEODE		= sblaster

#include    "$(SYSMAKEFILE)"
