##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson, Mar 28, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	hyprlnkec.geo		EC version
#	hyprlnk.geo		non-EC version
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	3/28/91		Initial Revision
#
# DESCRIPTION:
#	local makefile for hyperlink object
#
#	$Id: local.mk,v 1.1 97/04/04 18:09:20 newdeal Exp $
#
###############################################################################

ASMFLAGS        += -Wall
LINKFLAGS       += -Wunref

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE           = hyprlnk

#include    <$(SYSMAKEFILE)>
