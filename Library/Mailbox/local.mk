##############################################################################
#
# 	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Makefile
# FILE: 	local.mk<2>
# AUTHOR: 	Adam de Boor, Jun  1, 1994
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/ 1/94		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: local.mk,v 1.1 97/04/05 01:19:46 newdeal Exp $
#
###############################################################################

.PATH.ui	: UI $(INSTALL_DIR)/UI
.PATH.uih	: . $(INSTALL_DIR)

UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include    <$(SYSMAKEFILE)>

PCXREFFLAGS	+= -smailbox.sym 
