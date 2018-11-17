#############################################################################
#
#       Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:      GEOS
# MODULE:       Gadgets Library
# FILE:         local.mk
# AUTHOR:       Jacob A. Gabrielson, Nov 26, 1994
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       JAG	11/26/94	Initial revision
#
#
#	$Id: local.mk,v 1.1 97/04/04 17:59:54 newdeal Exp $
#
###############################################################################

ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK
#LINKFLAGS	+= -Wunref

#
# XIP
#
#ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

PCXREF		+= -sgadgetsec.sym

#include <$(SYSMAKEFILE)>
