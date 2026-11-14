##############################################################################
#
# 	Copyright (c) Geoworks 1997.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE: 	local.mk
# AUTHOR: 	Jeremy Broestl, Sep 26, 1997
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	jeremyb 	9/26/97   	Initial Revision
#
# DESCRIPTION:
#	file of compile flags for HTML
#	
#
#	$Id: local.mk,v 1.1.1.3 97/10/31 10:09:43 jeremyb Exp $
#
###############################################################################

GOCFLAGS	+= -DBROTHER_KERNEL
CCOMFLAGS       += -DBROTHER_KERNEL
LINKFLAGS	+= -DBROTHER_KERNEL
#include <$(SYSMAKEFILE)>



