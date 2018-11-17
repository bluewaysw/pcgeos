##############################################################################
#
#	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE:		local.mk
#
# AUTHOR:	Simon Auyeung, Aug  7, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	simon	8/ 7/95		Initial version.
#
# DESCRIPTION:
#
#	
#
#	$Id: local.mk,v 1.1 97/04/04 17:41:34 newdeal Exp $
#
##############################################################################

ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK

#
# SCRAMBLE_INI_STRINGS
#	Simple scrambling of access point strings in .ini file.  Currently
#	only used for ASPS_SECRET.
#
ASMFLAGS	+= -DSCRAMBLED_INI_STRINGS

#include        <$(SYSMAKEFILE)>

