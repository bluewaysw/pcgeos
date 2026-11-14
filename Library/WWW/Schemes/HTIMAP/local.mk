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
#	$Id: local.mk,v 1.2.6.1 97/09/05 10:52:18 jeremyb Exp $
#
###############################################################################

GOCFLAGS	+= -L htimap
# -D__LOG_HTIMAP__
# CCOMFLAGS       += -D__LOG_HTIMAP__

#include <$(SYSMAKEFILE)>

