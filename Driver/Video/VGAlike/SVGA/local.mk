##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	SVGA Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, 11/4/91
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	11/4/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the SVGA driver for the 
#	Super VGA 800x600 16-color modes
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:25 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../VGACom $(INSTALL_DIR:H)/VGACom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>
