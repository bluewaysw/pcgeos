##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	MCGA Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 20, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/20/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the MCGA driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:33 newdeal Exp $
#
###############################################################################
OBJS		:= $(OBJS:NmcgaUnder.obj)
EOBJS		:= $(EOBJS:NmcgaUnder.eobj)

.PATH.asm .PATH.def: ../DumbCom $(INSTALL_DIR:H)/DumbCom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>
