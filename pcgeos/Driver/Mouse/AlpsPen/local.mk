##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Mouse drivers
# FILE: 	local.mk
# AUTHOR: 	Jim Guggemos, Dec  6, 1994
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	JimG	12/ 6/94   	Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: local.mk,v 1.1 97/04/18 11:48:09 newdeal Exp $
#
###############################################################################

.PATH.asm .PATH.def	: .. $(INSTALL_DIR:H)

ASMFLAGS += -DHARDWARE_TYPE=GULLIVER

PROTOCONST	= MOUSE

#include <$(SYSMAKEFILE)>
