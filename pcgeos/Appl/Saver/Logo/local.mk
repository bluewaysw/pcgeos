##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Appl/Saver/Logo
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Aug 16, 1994
#
#	$Id: local.mk,v 1.1 97/04/04 16:49:40 newdeal Exp $
#
###############################################################################
#
# No error-checking version of this app
#
NO_EC		= 1

ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#include <$(SYSMAKEFILE)>
