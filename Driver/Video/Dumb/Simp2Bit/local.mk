##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Simp2Bit Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Joon Song, October 7, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Joon	10/7/96		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Simp2Bit driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:43:51 newdeal Exp $
#
###############################################################################
.PATH.asm .PATH.def: ../DumbCom $(INSTALL_DIR:H)/DumbCom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom \
		../VidMem/Clr2 $(INSTALL_DIR:H)/VidMem/Clr2

#include	<$(SYSMAKEFILE)>
