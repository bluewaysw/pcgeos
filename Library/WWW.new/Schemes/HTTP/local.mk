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
#	$Id: local.mk,v 1.1.8.1 97/09/05 10:51:25 jeremyb Exp $
#
###############################################################################

GOCFLAGS	+= -L http

CCOMFLAGS += -DSSL_ENABLE
GOCFLAGS += -DSSL_ENABLE

#include <$(SYSMAKEFILE)>

