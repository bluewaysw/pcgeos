##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PCL 4 Printer Driver
# FILE: 	local.mk
# AUTHOR: 	Dave Durran
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	Dave	1/92		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Printer Driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:52:21 newdeal Exp $
#
###############################################################################

#
# to allow i/o instructions, and interrupt disabling
#
ASMFLAGS	+= -i

.PATH.asm .PATH.def: ../../PrintCom $(INSTALL_DIR:H)/../PrintCom \
		.. $(INSTALL_DIR:H)

#
#
#
.PATH.uih .PATH.ui: UI ../../PrintCom $(INSTALL_DIR:H)/../PrintCom
UICFLAGS        += -IUI -I../../PrintCom -I$(INSTALL_DIR:H)/../PrintCom

#
# set include file path
#
-IFLAGS		= -I$(.TARGET:R) -I$(INSTALL_DIR)/$(.TARGET:R) \
		  -I. -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \
		  -I../../PrintCom -I$(INSTALL_DIR:H)/../PrintCom \
		  -I.. -I$(INSTALL_DIR:H)/..  \
		  -I$(INSTALL_DIR) \

#
# Tell what *_PROTO_{MAJOR,MINOR} constants to use for the driver protocol
#
PROTOCONST	= PRINT


#include	<$(SYSMAKEFILE)>
