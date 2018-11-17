##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	ATT6300 Driver -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, July 20, 1989
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/20/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the ATT6300 driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:42:39 newdeal Exp $
#
###############################################################################
OBJS		:= $(OBJS:Natt6300Under.obj)
EOBJS		:= $(EOBJS:Natt6300Under.eobj)

.PATH.asm .PATH.def: ../DumbCom $(INSTALL_DIR:H)/DumbCom \
		../../VidCom $(INSTALL_DIR:H)/../VidCom

#include	<$(SYSMAKEFILE)>
