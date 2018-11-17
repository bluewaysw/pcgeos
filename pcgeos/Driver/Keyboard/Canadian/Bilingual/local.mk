##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson, Jul  9, 1991
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	kbdb_cf.geo 	    	Bilingual Candian keyboard driver
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 9/91		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: local.mk,v 1.1 97/04/18 11:47:22 newdeal Exp $
#
###############################################################################
GEODE		= kbdb_cf
NO_EC		= 1

LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall

#
# Look in the common module too.
#
DEPFLAGS	+= -I.. -I$(INSTALL_DIR:H:H)

.PATH.def	: ../.. $(INSTALL_DIR:H:H)
.PATH.asm	: ../.. $(INSTALL_DIR:H:H)
.PATH.ui	: ../.. $(INSTALL_DIR:H:H)

#include <$(SYSMAKEFILE)>
