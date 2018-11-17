##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Studio -- special definitions
# FILE: 	local.mk
# AUTHOR: 	tony, 10/21/91
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tony	10/21/91	Initial Revision
#
# DESCRIPTION:
#	Special definitions for Studio
#
#	$Id: local.mk,v 1.1 97/04/04 14:40:51 newdeal Exp $
#
###############################################################################

.PATH.uih .PATH.ui: UI Document $(INSTALL_DIR)/UI $(INSTALL_DIR)/Document
UICFLAGS	+= -IUI -IDocument -I$(INSTALL_DIR)/UI -I$(INSTALL_DIR)/Document

#include <$(SYSMAKEFILE)>

PCXREFFLAGS	+= -sbindery.sym

ASMFLAGS	+= -DREAD_CHECK -DWRITE_CHECK
