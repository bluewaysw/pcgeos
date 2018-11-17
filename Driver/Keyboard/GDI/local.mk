##############################################################################
#
#	(c) Copyright Geoworks 1996 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	
# MODULE:	
# FILE:		local.mk
#
# AUTHOR:	Kenneth Liu, Apr 23, 1996
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	kliu	4/23/96		Initial version.
#
# 
#
#	$Id: local.mk,v 1.1 97/04/18 11:47:51 newdeal Exp $
#
##############################################################################
#
GEODE		= gdiKbd

LINKFLAGS	+= -Wunref
ASMFLAGS	+= -Wall 

#
# Look in he common module too.
#
DEPFLAGS	+= -I.. -I$(INSTALL_DIR:H)

.PATH.def	: .. $(INSTALL_DIR:H)
.PATH.asm	: .. $(INSTALL_DIR:H)
.PATH.ui	: .. $(INSTALL_DIR:H)

#include        <$(SYSMAKEFILE)>





