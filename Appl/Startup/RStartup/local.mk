##############################################################################
#
#	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	
# FILE:		local.mk
#
# AUTHOR:	Jason Ho, Sep  5, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	kho	9/ 5/95		Initial version.
#
# 	generic local.mk.
#
#	$Id: local.mk,v 1.1 97/04/04 16:52:41 newdeal Exp $
#
##############################################################################
#
# Enable memory error checking codes
ASMFLAGS        += -DREAD_CHECK -DWRITE_CHECK

# add anything above this line
#include        <$(SYSMAKEFILE)>
