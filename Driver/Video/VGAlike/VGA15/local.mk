##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	VGA8 Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, 10/92
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/92		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the VGA8 driver for the 
#	Super VGA 256-color modes
#
#	$Id: local.mk,v 1.2 96/08/05 03:51:53 canavese Exp $
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>

LINKFLAGS += -N "(C)97 Breadbox Computer Company"
