##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Dec 27, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	12/27/89	Initial Revision
#
# DESCRIPTION:
#	Special definitions for tools library
#
#	$Id: local.mk,v 1.4 92/08/30 14:22:18 josh Exp $
#
###############################################################################
#if defined(unix)
CFLAGS		+= -DMEM_TRACE -Wall
#endif

.PATH.h		: # biff CInclude...

#include    <$(SYSMAKEFILE)>
CFLAGS_COMMON = -d2 -w3 -zp=1
