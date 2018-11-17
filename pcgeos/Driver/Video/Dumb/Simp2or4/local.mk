##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Video
# FILE:		local.mk
#
# AUTHOR:	Eric Weber, Feb 12 1997
#
#
# 
#
#	$Id: local.mk,v 1.1 97/04/18 11:43:57 newdeal Exp $
#
##############################################################################

# turn on read and write checking, and turn off the myriad jump out of 
# bounds warnings which they would normally cause
ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK 

PCXREF	+= -ssimp2or4ec.sym

#include <$(SYSMAKEFILE)>
