##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	HotSpot
# FILE: 	local.mk
# AUTHOR: 	Cassie Hartzog, November 18, 1994
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	cassie	11/18/94    	Initial version
#
# DESCRIPTION:
#	local makefile for HotSpot library
#
#	$Id: local.mk,v 1.1 97/04/04 18:09:13 newdeal Exp $
#
###############################################################################

ASMFLAGS        += -Wall 

#LINKFLAGS       += -Wunref -r
GOCFLAGS	+= -L hotspot

#include    <$(SYSMAKEFILE)>
