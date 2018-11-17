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
#	$Id: local.mk,v 1.1 97/04/18 11:42:06 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>
