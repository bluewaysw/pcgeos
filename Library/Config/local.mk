##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1995 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	
# FILE: 	local.mk
# AUTHOR: 	Andrew Wilson, Nov 20, 1995
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	11/20/95		Initial Revision
#
# DESCRIPTION:
#	Sets compile flags for TOCONLY version.
#
#	$Id$
#
###############################################################################
ASMFLAGS        += $(.TARGET:X\\[TOCONLY\\]/*:S|TOCONLY| -DTOC_ONLY |g)
LINKFLAGS       += $(.TARGET:X\\[TOCONLY\\]/*:S|TOCONLY| -DTOC_ONLY |g)

#include "$(SYSMAKEFILE)"
