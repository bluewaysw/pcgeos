##############################################################################
#
#	Copyright (c) GeoWorks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# FILE:		local.mk
#
# AUTHOR:	Eric Weber, Sep  5, 1995
#
#
# 
#
#	$Id: local.mk,v 1.1 97/04/05 01:25:34 newdeal Exp $
#
##############################################################################


ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK

PCXREF	+= -snetutilsec.sym

#include <$(SYSMAKEFILE)>

