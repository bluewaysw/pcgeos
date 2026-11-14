##############################################################################
#
# 	Copyright (c) GeoWorks 1997 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Kok Kin Kee, April 7, 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	kkee	4/7/97	    	Initial version
#
# DESCRIPTION:
#	local makefile for www library
#
#	$Id: local.mk,v 1.1.8.2 97/11/19 23:32:43 jeremyb Exp $
#
###############################################################################

GOCFLAGS	+= -L htjpeg -DBROTHER_KERNEL
CCOMFLAGS       += -DBROTHER_KERNEL
LINKFLAGS	+= -DBROTHER_KERNEL

#include <$(SYSMAKEFILE)>
