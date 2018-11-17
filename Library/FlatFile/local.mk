##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Jeremy Dashe, January 22, 1992
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	ffileec.geo		EC version
#	ffile.geo		non-EC version
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jeremy	1/22/92	    	Initial version
#
# DESCRIPTION:
#	local makefile for flat file database object
#
#	$Id: local.mk,v 1.1 97/04/04 18:03:25 newdeal Exp $
#
###############################################################################

## ASMFLAGS        += -Wall
## LINKFLAGS       += -Wunref -r
GOCFLAGS	+= -L ffile

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE           = ffile

#include    <$(SYSMAKEFILE)>
