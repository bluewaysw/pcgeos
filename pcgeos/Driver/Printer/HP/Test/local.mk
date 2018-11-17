##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Test Printer Driver
# FILE: 	local.mk
# AUTHOR: 	Don Reeves, July 10, 1994
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	don 	7/10/94		Initial Revision
#
# DESCRIPTION:
#	Special definitions required for the Printer Driver
#
#	$Id: local.mk,v 1.1 97/04/18 11:52:33 newdeal Exp $
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
.PATH.uih .PATH.ui: UI ../../PrintCom $(INSTALL_DIR:H)/../PrintCom \
                    $(INSTALL_DIR:H)/../../../Library/Spool/Art
UICFLAGS        += -IUI -I../../PrintCom -I$(INSTALL_DIR:H)/../PrintCom \
                    -I$(INSTALL_DIR:H)/../../../Library/Spool/Art

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
