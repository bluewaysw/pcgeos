##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Keyboard drivers -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 19, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/19/89		Initial Revision
#
# DESCRIPTION:
#	Wrong name for directory, and we don't *do* error checking...
#
#	$Id: local.mk,v 1.1 97/04/18 11:47:10 newdeal Exp $
#
###############################################################################
GEODE		= kbdn_fr
NO_EC		= 1

LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall

#
# Look in the common-ui module too.
#
DEPFLAGS	+= -I.. -I$(INSTALL_DIR:H:H)

.PATH.def	: ../.. $(INSTALL_DIR:H:H)
.PATH.asm	: ../.. $(INSTALL_DIR:H:H)
.PATH.ui	: ../.. $(INSTALL_DIR:H:H)

#include <$(SYSMAKEFILE)>

