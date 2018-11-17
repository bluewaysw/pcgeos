##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Kernel -- Special Makefile Definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 16, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/16/89		Initial Revision
#	JDM	93.04.29	Added Profiling version support.
#
# DESCRIPTION:
#	Kernel special makefile definitions.
#
#	$Id: local.mk,v 1.1 97/04/04 18:04:06 newdeal Exp $
#
###############################################################################

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#
# The kernel needs to use I/O instructions for some strange reason...
#
ASMFLAGS	+= -i

# for special WIN32DBCS version
ASMFLAGS        += $(.TARGET:MWIN32*:S/$(.TARGET)/-DWIN32 -DHARDWARE_TYPE=PC/)

#
#	The target is genpcgdi.geo
#
GEODE		= gdi

#
# There are no strings to localize.
#
NO_LOC		=

#include    "$(SYSMAKEFILE)"

