##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	MEGA Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Jeremy Dashe, April 12, 1991
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	jeremy	4/12/91		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the MEGA driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:19 newdeal Exp $
#
###############################################################################
ASMFLAGS	+= -i
OBJS		:= $(OBJS:NmegaUnder.obj:NmegaEscTab.obj)
EOBJS		:= $(EOBJS:NmegaUnder.eobj:NmegaEscTab.eobj)

.PATH.asm .PATH.def: ../../VidCom $(INSTALL_DIR:H)/../VidCom \
../../Dumb/DumbCom $(INSTALL_DIR:H)/../Dumb/DumbCom \
../VGACom $(INSTALL_DIR:H)/VGACom

#include	<$(SYSMAKEFILE)>
