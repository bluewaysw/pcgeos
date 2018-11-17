##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE:		local.mk
# AUTHOR:	Paul L. DuBois, Nov 10, 1994
#
# COMMANDS:
#	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dubois	11/10/94	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: local.mk,v 1.1 97/05/30 06:49:00 newdeal Exp $
#
###############################################################################

# This causes tagging code to be assembled, but only if ERROR_CHECK is also
# defined (see hashGeod.def)
ASMFLAGS	+= -DDO_ERROR_CHECK_TAG

#include <$(SYSMAKEFILE)>
