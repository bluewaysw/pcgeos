##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Tools/ResEdit
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, Mon Jul 29 14:16:44 PST 1991
#
#	$Id: local.mk,v 1.1 97/04/04 17:13:46 newdeal Exp $
#
###############################################################################
.PATH.ui        : UI $(INSTALL_DIR)/UI

UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI
ASMFLAGS	+= 
ASMWARNINGS	= -Wall -wprivate
LINKFLAGS	+=

#include <$(SYSMAKEFILE)>
