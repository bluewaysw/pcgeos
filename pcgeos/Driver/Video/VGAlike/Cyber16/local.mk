##############################################################################
#
# 	Copyright (c) Global PC 1998 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Cyber16 Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, 10/92
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/92		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Cyber16 driver for the 
#	IGS CyberPro 2010 64K-color modes
#
#	$Id: local.mk,v 1.2$
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../VidCom $(INSTALL_DIR:H)/../VidCom ../VGA16 $(INSTALL_DIR:H)/VGA16

#include	<$(SYSMAKEFILE)>
