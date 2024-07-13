##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1995 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	DataStore
# FILE: 	local.mk
# AUTHOR: 	Cassie Hartzog, Oct 5, 1995
#
#	$Id: local.mk,v 1.1 97/04/04 17:53:52 newdeal Exp $
#
###############################################################################
#
#	Define flags to handle the GCM version, program is called "datastor"
#
GEODE		= datastor

#
# Turn on read/write checking
#
ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#
# Turn on useful compile/link warnings
#
ASMFLAGS	+= -Wunreach -Wshadow 
ASMWARNINGS	 = -Wall -wprivate
LINKFLAGS	+= -Wunref

#include <$(SYSMAKEFILE)>
