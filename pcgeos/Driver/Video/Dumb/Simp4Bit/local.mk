##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Simp4Bit Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 20, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/20/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Simp4Bit driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:43:47 newdeal Exp $
#
###############################################################################
.PATH.asm .PATH.def: ../DumbCom $(INSTALL_DIR:H)/DumbCom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom \
		../VidMem/Clr4 $(INSTALL_DIR:H)/VidMem/Clr4

#include	<$(SYSMAKEFILE)>
