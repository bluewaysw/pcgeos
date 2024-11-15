##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Makefile
# FILE: 	local.mk
# AUTHOR: 	Gene Anderson, Mar 21, 1994
#
#	$Id: local.mk,v 1.1 97/04/04 17:27:38 newdeal Exp $
#
###############################################################################

# This beastie is a .exe program
GEODE=loader
GSUFF=exe

# To make the DBCS version, since we have a DBCS version of a Text product.
PRODUCT = $(.TARGET:X\\[DBCS\\]/*:S|DBCS|DBCS|g)

ASMFLAGS += -DNO_SPLASH_SCREEN -DNO_AUTODETECT -DGEOS32

.PATH.asm .PATH.def: .. $(INSTALL_DIR:H)

#include <$(SYSMAKEFILE)>
