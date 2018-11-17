##############################################################################
#
# 	Copyright (c) Global PC 1998 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	VGA16 Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, 10/92
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/92		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the VGA16 driver for the 
#	VESA Compatible SVGA 64K-color modes
#
#	$Id: local.mk,v 1.2$
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../VidCom $(INSTALL_DIR:H)/../VidCom

# for special WIN32DBCS version
ASMFLAGS        += $(.TARGET:MWIN32*:S/$(.TARGET)/-DWIN32 -DHARDWARE_TYPE=PC/)

#include	<$(SYSMAKEFILE)>
