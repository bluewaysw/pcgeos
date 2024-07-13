##############################################################################
#
#	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS
# MODULE:	Telnet library
# FILE:		local.mk
#
# AUTHOR:	Simon Auyeung, Aug 15, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	simon	8/15/95		Initial version.
#
# DESCRIPTION:
#
#	
#
#	$Id: local.mk,v 1.1 97/04/07 11:16:16 newdeal Exp $
#
##############################################################################

ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK
PCXREF		+= -stelnetec.sym

#include    <$(SYSMAKEFILE)>
