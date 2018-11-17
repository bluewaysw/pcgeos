##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	local.mk
# FILE: 	local.mk
# AUTHOR:   	jimmy
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	80X87ec.geo		EC version
#	80X87.geo		non-EC version
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jimmy	4/20/92		Initial Revision
#
# DESCRIPTION:
#	local makefile for 80x87 library
#
#	$Id: local.mk,v 1.1 97/04/04 17:48:46 newdeal Exp $
#
###############################################################################

ASMFLAGS        += -Wall 
LINKFLAGS       += -Wunref

# Another geode that bucks conventions -- we need to change the GEODE variable
GEODE           = int8087

.PATH.asm .PATH.def : ../IntCommon $(INSTALL_DIR:H)/IntCommon

-IFLAGS		+= -I../IntCommon -I$(INSTALL_DIR:H)/IntCommon 

#include    <$(SYSMAKEFILE)>


