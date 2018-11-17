#####################################################################
#
#	Copyright (c) Geoworks 1992-96 -- All Rights Reserved.
#
# PROJECT:	GEOS Sample Applications
# MODULE:	Levels
# FILE:		local.mk
#
# AUTHOR:	John D. Mitchell, 92.10.13
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       JDM     10/13/92        Initial version
#
# DESCRIPTION:
#	These flags will be incorporating into the make. You can
#       pass flags to GOC, the C compiler, and the glue linker.
#
# RCS STAMP:
#	$Id: local.mk,v 1.1 97/04/04 16:37:30 newdeal Exp $
#
#####################################################################
#
# Pass the linker flag for resource fix-ups for multi-launchability.
#
LINKFLAGS += -r
#
# Include the system makefile.
#
#include <$(SYSMAKEFILE)>

