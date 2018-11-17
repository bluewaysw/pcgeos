##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Tools/ProtoBiffer
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Mon Jul 29 14:16:44 PST 1991
#
#	$Id: local.mk,v 1.1 97/04/04 17:15:08 newdeal Exp $
#
###############################################################################
#
#	Program is called "proto.geo"
#
GEODE		= proto

ASMFLAGS	+= -Wall
LINKFLAGS	+=

#include <$(SYSMAKEFILE)>
