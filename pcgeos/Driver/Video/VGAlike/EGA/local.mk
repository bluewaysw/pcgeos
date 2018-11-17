##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	EGA Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jim DeFrisco, October 28, 1991
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jim	10/28/91	Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the EGA driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:08 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../VGACom $(INSTALL_DIR:H)/VGACom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>
