##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Socket
# FILE:		local.mk
#
# AUTHOR:	Eric Weber, Nov 17, 1994
#
#
# 
#
#	$Id: local.mk,v 1.1 97/04/07 10:46:10 newdeal Exp $
#
##############################################################################

# turn on read and write checking, and turn off the myriad jump out of 
# bounds warnings which they would normally cause
#ASMFLAGS += -DREAD_CHECK -DWRITE_CHECK 

PCXREF	+= -ssocketec.sym

#include <$(SYSMAKEFILE)>
