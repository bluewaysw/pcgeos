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
#	$Id: local.mk,v 1.1.8.3 97/09/08 17:51:50 jeremyb Exp $
#
###############################################################################

GOCFLAGS	+= -L htgif -DBROTHER_KERNEL -DGPC_VERSION
CCOMFLAGS	+= -DBROTHER_KERNEL -DGPC_VERSION

ASMFLAGS	+= -DBROTHER_KERNEL -DGPC_VERSION
#include <$(SYSMAKEFILE)>
