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
#	$Id: local.mk,v 1.1.8.2 97/09/08 15:26:45 jeremyb Exp $
#
###############################################################################

# Define TRUNK for use as conditional compilations in trunk, ReleaseResponder,
# and other main versions.
GOCFLAGS	+= -L uigenera -DTRUNK -DBROTHER_KERNEL
CCOMFLAGS       += -DTRUNK -DBROTHER_KERNEL

#include <$(SYSMAKEFILE)>
